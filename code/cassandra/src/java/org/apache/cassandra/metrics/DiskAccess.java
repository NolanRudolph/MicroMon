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

import java.io.IOException;

import org.apache.cassandra.io.IVersionedSerializer;
import org.apache.cassandra.io.util.DataInputPlus;
import org.apache.cassandra.io.util.DataOutputPlus;
import org.apache.cassandra.net.MessageOut;
import org.apache.cassandra.net.MessagingService;
import org.apache.cassandra.db.TypeSizes;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class DiskAccess
{
    protected static final Logger logger = LoggerFactory.getLogger(DiskAccess.class);

    public static final DiskAccessSerializer serializer = new DiskAccessSerializer();

    public final double latency;

    public DiskAccess(double diskAccessTime)
    {
      this.latency = diskAccessTime;
    }

    public MessageOut createMessage()
    {
	logger.info("@@@ DISK ACCESS MESSAGE OUT w/ LATENCY: {} @@@", Double.toString(this.latency));
        return new MessageOut<DiskAccess>(MessagingService.Verb.DISK_ACCESS, this, serializer);
    }
}

class DiskAccessSerializer implements IVersionedSerializer<DiskAccess>
{
    public void serialize(DiskAccess diskAccess, DataOutputPlus out, int version) throws IOException
    {
        out.writeUTF(Double.toString(diskAccess.latency));
    }

    public DiskAccess deserialize(DataInputPlus in, int version) throws IOException
    {
        Double diskLatency = Double.parseDouble(in.readUTF());
        return new DiskAccess(diskLatency);
    }

    public long serializedSize(DiskAccess da, int version)
    {
	long size = 1; // message type (single byte)
        size += (long) Double.BYTES;
	return size;
    }
}
