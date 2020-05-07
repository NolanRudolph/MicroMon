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
package org.apache.cassandra.metrics;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import org.apache.cassandra.locator.DynamicEndpointSnitch;
import org.apache.cassandra.metrics.DiskAccess;
import org.apache.cassandra.net.IVerbHandler;
import org.apache.cassandra.net.MessageIn;
import org.apache.cassandra.net.MessageOut;
import org.apache.cassandra.net.MessagingService;

import java.io.*;

public class DiskAccessVerbHandler implements IVerbHandler<DiskAccess>
{
    private static final Logger logger = LoggerFactory.getLogger(DiskAccessVerbHandler.class);

    public void doVerb(MessageIn<DiskAccess> message, int id)
    {
        DiskAccess payload = message.payload;

	    if (payload.isHost)
	    {
            double DALatency = 0.0;

            // Read in the updated disk access latency
            try
            {
                File file = new File("/users/NolanR/diskAccess.txt");
                BufferedReader br = new BufferedReader(new FileReader(file));
                DALatency = Double.parseDouble(br.readLine());
            }
            catch (Exception e)
            {
                logger.error("ERROR : " + e);
            }

            logger.info("@@@@@@@ RETRIEVED AND SENDING PAYLOAD " + Double.toString(DALatency) + " @@@@@@@");

            // Create a return message and send it to requester
		    DiskAccess retPayload = new DiskAccess(false, DALatency);
		    DiskAccessSerializer serializer = new DiskAccessSerializer();
		    MessageOut<DiskAccess> reply = new MessageOut<DiskAccess>(MessagingService.Verb.DISK_ACCESS, retPayload, serializer);

		    MessagingService.instance().sendReply(reply, id, message.from);
	    }
	    else
	    {
		    logger.info("@@@@@@@@@@ GOT MESSAGE WITH PAYLOAD : " + payload.latency + "@@@@@@@@@@@@@");
		    DynamicEndpointSnitch.diskAccess.put(message.from, payload.latency);
	    }
    }
}
