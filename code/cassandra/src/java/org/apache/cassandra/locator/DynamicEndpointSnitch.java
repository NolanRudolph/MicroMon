/*
 * Licensed to the Apache Software Foundation (ASF) under one
 * or more contributor license agreements.  See the NOTICE file
 * distributed with this work for additional information
 * regarding copyright ownership.  The ASF licenses this file
 * to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance
 * with the License.  You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package org.apache.cassandra.locator;

import java.net.InetAddress;
import java.net.UnknownHostException;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ScheduledFuture;
import java.util.concurrent.TimeUnit;
import java.util.*;
import java.lang.System;
import java.io.*;

import com.codahale.metrics.ExponentiallyDecayingReservoir;

import com.codahale.metrics.Snapshot;
import org.apache.cassandra.concurrent.ScheduledExecutors;
import org.apache.cassandra.config.DatabaseDescriptor;
import org.apache.cassandra.gms.ApplicationState;
import org.apache.cassandra.gms.EndpointState;
import org.apache.cassandra.gms.Gossiper;
import org.apache.cassandra.gms.VersionedValue;
import org.apache.cassandra.net.MessagingService;
import org.apache.cassandra.net.MessageOut;
import org.apache.cassandra.net.MessageIn;
import org.apache.cassandra.net.MessageDeliveryTask;
import org.apache.cassandra.service.StorageService;
import org.apache.cassandra.utils.FBUtilities;
import org.apache.cassandra.utils.MBeanWrapper;
import org.apache.cassandra.metrics.DiskAccess;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;


/**
 * A dynamic snitch that sorts endpoints by latency with an adapted phi failure detector
 */
public class DynamicEndpointSnitch extends AbstractEndpointSnitch implements ILatencySubscriber, DynamicEndpointSnitchMBean
{
    private static final double ALPHA = 0.75; // set to 0.75 to make EDS more biased to towards the newer values
    private static final int WINDOW_SIZE = 100;

    private volatile int dynamicUpdateInterval = DatabaseDescriptor.getDynamicUpdateInterval();
    private volatile int dynamicResetInterval = DatabaseDescriptor.getDynamicResetInterval();

    // the score for a merged set of endpoints must be this much worse than the score for separate endpoints to
    // warrant not merging two ranges into a single range
    private static final double RANGE_MERGING_PREFERENCE = 1.5;

    private String mbeanName;
    private boolean registered = false;

    private volatile HashMap<InetAddress, Double> scores = new HashMap<>();
    public static HashMap<InetAddress, Double> diskAccess = new HashMap<>();
    private final ConcurrentHashMap<InetAddress, ExponentiallyDecayingReservoir> samples = new ConcurrentHashMap<>();

    public final IEndpointSnitch subsnitch;

    private volatile ScheduledFuture<?> updateSchedular;
    private volatile ScheduledFuture<?> resetSchedular;

    private final Runnable update;
    private final Runnable reset;

    private long timer = System.currentTimeMillis();

    // EDIT:
    // Stores important attributes about a node
    public class Node
    {
        String name;
        String ip;

        public Node(String n, String IP)
        {
            name = n;
            ip = IP;
        }
    }

    // EDIT:
    // List to be referenced for updating scores
    HashMap<String, Node> nodeConfigs = new HashMap<String, Node>();

    // EDIT:
    // DynamicEndpointSnitch now has debugging access to system.log
    protected static final Logger logger = LoggerFactory.getLogger(DynamicEndpointSnitch.class);

    public DynamicEndpointSnitch(IEndpointSnitch snitch)
    {
        this(snitch, null);
    }

    public DynamicEndpointSnitch(IEndpointSnitch snitch, String instance)
    {
        // EDIT:
        // This gathers all the details from my file pertaining to node
        // attributes
        try
        {
            File file = new File("cassandra_config.txt");
            BufferedReader br = new BufferedReader(new FileReader(file));
            int nodes = Integer.parseInt(br.readLine());
            for (int i = 0; i < nodes; i++)
            {
                String curConfig = br.readLine();
                String[] configParse = curConfig.split(",");
                String name  = configParse[0];  // Name of Node
                String ip    = configParse[1];  // IP of Node
                Node newNode = new Node(name, ip);

                // Store back into nodeConfigs with key being the IP
                // This allows for easy indexing since this module heavily utilizes IPs
                nodeConfigs.put(ip, newNode);
            }
        }
        catch (Exception e)
        {
            logger.error("ERROR: " + e);
        }

        mbeanName = "org.apache.cassandra.db:type=DynamicEndpointSnitch";
        if (instance != null)
            mbeanName += ",instance=" + instance;
        subsnitch = snitch;
        update = new Runnable()
        {
            public void run()
            {
                updateScores();
            }
        };
        reset = new Runnable()
        {
            public void run()
            {
                // we do this so that a host considered bad has a chance to recover, otherwise would we never try
                // to read from it, which would cause its score to never change
                reset();
            }
        };

        if (DatabaseDescriptor.isDaemonInitialized())
        {
            updateSchedular = ScheduledExecutors.scheduledTasks.scheduleWithFixedDelay(update, dynamicUpdateInterval, dynamicUpdateInterval, TimeUnit.MILLISECONDS);
            resetSchedular = ScheduledExecutors.scheduledTasks.scheduleWithFixedDelay(reset, dynamicResetInterval, dynamicResetInterval, TimeUnit.MILLISECONDS);
            registerMBean();
        }
    }

    /**
     * Update configuration from {@link DatabaseDescriptor} and estart the update-scheduler and reset-scheduler tasks
     * if the configured rates for these tasks have changed.
     */
    public void applyConfigChanges()
    {
        if (dynamicUpdateInterval != DatabaseDescriptor.getDynamicUpdateInterval())
        {
            dynamicUpdateInterval = DatabaseDescriptor.getDynamicUpdateInterval();
            if (DatabaseDescriptor.isDaemonInitialized())
            {
                updateSchedular.cancel(false);
                updateSchedular = ScheduledExecutors.scheduledTasks.scheduleWithFixedDelay(update, dynamicUpdateInterval, dynamicUpdateInterval, TimeUnit.MILLISECONDS);
            }
        }

        if (dynamicResetInterval != DatabaseDescriptor.getDynamicResetInterval())
        {
            dynamicResetInterval = DatabaseDescriptor.getDynamicResetInterval();
            if (DatabaseDescriptor.isDaemonInitialized())
            {
                resetSchedular.cancel(false);
                resetSchedular = ScheduledExecutors.scheduledTasks.scheduleWithFixedDelay(reset, dynamicResetInterval, dynamicResetInterval, TimeUnit.MILLISECONDS);
            }
        }
    }

    private void registerMBean()
    {
        MBeanWrapper.instance.registerMBean(this, mbeanName);
    }

    public void close()
    {
        updateSchedular.cancel(false);
        resetSchedular.cancel(false);

        MBeanWrapper.instance.unregisterMBean(mbeanName);
    }

    @Override
    public void gossiperStarting()
    {
        subsnitch.gossiperStarting();
    }

    public String getRack(InetAddress endpoint)
    {
        return subsnitch.getRack(endpoint);
    }

    public String getDatacenter(InetAddress endpoint)
    {
        return subsnitch.getDatacenter(endpoint);
    }

    public List<InetAddress> getSortedListByProximity(final InetAddress address, Collection<InetAddress> addresses)
    {
        List<InetAddress> list = new ArrayList<InetAddress>(addresses);
        sortByProximity(address, list);
        return list;
    }

    @Override
    public void sortByProximity(final InetAddress address, List<InetAddress> addresses)
    {
        assert address.equals(FBUtilities.getBroadcastAddress()); // we only know about ourself
        sortByProximityWithScore(address, addresses);
    }

    // EDIT: Here all my work below comes into place. The points are being
    // constantly updated via updateScores(), and when the replication factor
    // > 1, it is utilized using this method. I've since deleted other sorting
    // methods such as sortByProximityWithBadness.
    private void sortByProximityWithScore(final InetAddress address, List<InetAddress> addresses)
    {
        // Scores can change concurrently from a call to this method. But Collections.sort() expects
        // its comparator to be "stable", that is 2 endpoint should compare the same way for the duration
        // of the sort() call. As we copy the scores map on write, it is thus enough to alias the current
        // version of it during this call.
        final HashMap<InetAddress, Double> scores = this.scores;
        Collections.sort(addresses, new Comparator<InetAddress>()
        {
            public int compare(InetAddress a1, InetAddress a2)
            {
                return compareEndpoints(address, a1, a2, scores);
            }
        });
    }

    private int compareEndpoints(InetAddress target, InetAddress a1, InetAddress a2, Map<InetAddress, Double> scores)
    {
        Double scored1 = scores.get(a1);
        Double scored2 = scores.get(a2);
        
        if (scored1 == null)
            scored1 = 0.0;

        if (scored2 == null)
            scored2 = 0.0;

        if (scored1.equals(scored2))
            return subsnitch.compareEndpoints(target, a1, a2);
        if (scored1 < scored2)
            return -1;
        else
            return 1;
    }

    public int compareEndpoints(InetAddress target, InetAddress a1, InetAddress a2)
    {
        // That function is fundamentally unsafe because the scores can change at any time and so the result of that
        // method is not stable for identical arguments. This is why we don't rely on super.sortByProximity() in
        // sortByProximityWithScore().
        throw new UnsupportedOperationException("You shouldn't wrap the DynamicEndpointSnitch (within itself or otherwise)");
    }

    public void receiveTiming(InetAddress host, long latency) // this is cheap
    {
        ExponentiallyDecayingReservoir sample = samples.get(host);
        if (sample == null)
        {
            ExponentiallyDecayingReservoir maybeNewSample = new ExponentiallyDecayingReservoir(WINDOW_SIZE, ALPHA);
            sample = samples.putIfAbsent(host, maybeNewSample);
            if (sample == null)
                sample = maybeNewSample;
        }

        sample.update(latency);
    }

    // NWL: Network Latency
    // DAL: Disk Access Latency
    private void updateScores() // this is expensive
    {
        if (!StorageService.instance.isGossipActive())
            return;
        if (!registered)
        {
            if (MessagingService.instance() != null)
            {
                MessagingService.instance().register(this);
                registered = true;
            }

        }

        // Lots of overhead, so set to occur every 5s
        if (System.currentTimeMillis() - timer > 5000)
        {
            // Reset timer to 5 minutes
            timer = System.currentTimeMillis();

            double myDAL = 0.0;
            // Retrieve current disk access to tell other nodes
            try
            {
                File file = new File("/users/NolanR/diskAccess.txt");
                BufferedReader br = new BufferedReader(new FileReader(file));
                myDAL = Double.parseDouble(br.readLine());
            }
            catch (Exception e)
            {
                logger.error("ERROR : " + e);
            }
            

            // Create a new message to retrieve Disk Access time from other nodes
            // Note: This also informs said nodes about this nodes own DAL
            DiskAccess request = new DiskAccess(true, myDAL);
            MessageOut<DiskAccess> message = request.createMessage();
            
            // Loop through all addresses and request disk access information
            for (Map.Entry<InetAddress, ExponentiallyDecayingReservoir> entry : samples.entrySet())
            {
                if (!diskAccess.containsKey(entry.getKey()))
                    diskAccess.put(entry.getKey(), -1.0);

                MessagingService.instance().sendOneWay(message, entry.getKey());
            }
        }

        double maxNWL = 1;
        double maxDAL = 0.0000001;

        Map<InetAddress, Snapshot> snapshots = new HashMap<>(samples.size());
        for (Map.Entry<InetAddress, ExponentiallyDecayingReservoir> entry : samples.entrySet())
        {
            snapshots.put(entry.getKey(), entry.getValue().getSnapshot());
        }

        // We weight the latency for each host against the worst one we see, to
        // arrive at sort of a 'badness percentage' for them. First, find the worst for each:
        HashMap<InetAddress, Double> newScores = new HashMap<>();
        for (Map.Entry<InetAddress, Snapshot> entry : snapshots.entrySet())
        {
            // Network Latency
            double meanNWL = entry.getValue().getMedian();

            if (meanNWL > maxNWL)
                maxNWL = meanNWL;

            // Disk Access Latency
            double DAL = diskAccess.get(entry.getKey());

            // 40.51 is the DAL to represent host
            if (DAL > maxDAL && maxDAL != 40.51)
                maxDAL = DAL;
        }

        // now make another pass to do the weighting based on the maximums we found before
        for (Map.Entry<InetAddress, Snapshot> entry : snapshots.entrySet())
        {
            double score = entry.getValue().getMedian() / maxNWL;
            double influence = diskAccess.get(entry.getKey()) / maxDAL;

            logger.info("(" + entry.getKey().getHostAddress() + ") " 
                        + "Initial Score: " + Double.toString(score) + " | "
                        + "Influenced Score: " + Double.toString(score + influence));

            score += influence;

            // Score should not exceed 1.0
            score = score > 1.0 ? 1.0 : score;

            newScores.put(entry.getKey(), score);
        }
        
        // DEBUGGING
        logger.info("SCORES");
        for (Map.Entry<InetAddress, Double> entry : newScores.entrySet())
        {
            logger.info(entry.getKey().getHostAddress() + " : " + entry.getValue());
        }
        logger.info("DISK ACCESS");
        for (Map.Entry<InetAddress, Double> entry : diskAccess.entrySet())
        {
            logger.info(entry.getKey().getHostAddress() + " : " + entry.getValue());
        }

        scores = newScores;
    }

    private void reset()
    {
       samples.clear();
    }

    public Map<InetAddress, Double> getScores()
    {
        return scores;
    }

    public int getUpdateInterval()
    {
        return dynamicUpdateInterval;
    }
    public int getResetInterval()
    {
        return dynamicResetInterval;
    }

    public String getSubsnitchClassName()
    {
        return subsnitch.getClass().getName();
    }

    public List<Double> dumpTimings(String hostname) throws UnknownHostException
    {
        InetAddress host = InetAddress.getByName(hostname);
        ArrayList<Double> timings = new ArrayList<Double>();
        ExponentiallyDecayingReservoir sample = samples.get(host);
        if (sample != null)
        {
            for (double time: sample.getSnapshot().getValues())
            {
                timings.add(time);
            }
        }
        return timings;
    }

    // This returns whether a range query doing a query against merged is
    // likely to be faster than 2 sequential queries (i.e. merged vs. l1 + l2)
    public boolean isWorthMergingForRangeQuery(List<InetAddress> merged, List<InetAddress> l1, List<InetAddress> l2)
    {
        // skip checking scores in the single-node case
        if (l1.size() == 1 && l2.size() == 1 && l1.get(0).equals(l2.get(0)))
            return true;

        // Make sure we return the subsnitch decision (i.e true if we're here) if we lack
        // too much scores
        double maxMerged = maxScore(merged);
        double maxL1 = maxScore(l1);
        double maxL2 = maxScore(l2);
        if (maxMerged < 0 || maxL1 < 0 || maxL2 < 0)
            return true;

        return maxMerged <= (maxL1 + maxL2) * RANGE_MERGING_PREFERENCE;
    }

    // Return the max score for the endpoint in the provided list, or -1.0 if no node have a score.
    private double maxScore(List<InetAddress> endpoints)
    {
        double maxScore = -1.0;
        for (InetAddress endpoint : endpoints)
        {
            Double score = scores.get(endpoint);
            if (score == null)
                continue;

            if (score > maxScore)
                maxScore = score;
        }
        return maxScore;
    }
}
/* DEBUGGING STACK TRACE
logger.info("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@");
logger.info("(" + host.getHostAddress() + ") Latency : " + Long.toString(latency));
StackTraceElement[] stackTraceElements = Thread.currentThread().getStackTrace();
logger.info("Caller: " + stackTraceElements[2].getFileName());
logger.info("Method: " + stackTraceElements[2].getMethodName() + " @ Line " + stackTraceElements[2].getLineNumber());
logger.info("       Caller: " + stackTraceElements[3].getFileName());
logger.info("       Method: " + stackTraceElements[3].getMethodName() + " @ Line " + stackTraceElements[3].getLineNumber());
logger.info("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@");
*/

/* OLD METHOD OF SCORE INFLUENCE
// Initialize influence and retrieve respective node
double influence = 0.0; 
Node curNode = nodeConfigs.get(entry.getKey().getHostAddress());

// Divide by maxDiskAccess analagous to the score calculation seen above
influence += curNode.diskAccess / maxDiskAccess;

// Add this to the score
score += influence;
*/

/* STEP 3 - GETTING CASSANDRA LATENCY SCORES
long allVals[] = entry.getValue().getValues();
logger.info("(" + entry.getKey().getHostAddress() + ") Latencies: " + Arrays.toString(allVals));
String recent = Long.toString(allVals[allVals.length - 1]);
logger.info("(" + entry.getKey().getHostAddress() + ") Latency : " + recent);
*/
