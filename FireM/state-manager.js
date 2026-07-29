const Redis = require('ioredis');


const redisConfig = { host: '172.17.33.10', port: 6379 };
const redisClient = new Redis(redisConfig);
const redisSubscriber = new Redis(redisConfig);
const redisPublisher = new Redis(redisConfig);

const BUCKET_CAPACITY = 64; 

class GlobalStateManager {
    constructor() {
        this.virtualServers = new Map();
        this.redisClient = redisClient;
        this.redisPublisher = redisPublisher;
        this.initializeSubscriber();
    }

    
    initializeSubscriber() {
        redisSubscriber.subscribe('global_chat', 'system_announcement', (err, count) => {
            if (err) console.error('[Redis] Subscription Error:', err);
        });

        redisSubscriber.on('message', (channel, message) => {
            const payload = JSON.parse(message);
            
            if (channel === 'global_chat') {
                console.log(`[Global Chat] [Bucket ${payload.bucket}] ${payload.author}: ${payload.text}`);
                
                
            }
        });
    }

    
    async assignPlayerToBucket(license, targetBucket) {
        const currentPlayers = await redisClient.scard(`bucket_players:${targetBucket}`);
        
        if (currentPlayers >= BUCKET_CAPACITY) {
            return { success: false, reason: "Virtual Server is currently full." };
        }

        
        await redisClient.sadd(`bucket_players:${targetBucket}`, license);
        
        
        await redisClient.set(`player_location:${license}`, targetBucket);
        
        return { success: true, bucket: targetBucket };
    }

    
    async removePlayer(license) {
        const currentBucket = await redisClient.get(`player_location:${license}`);
        if (currentBucket) {
            await redisClient.srem(`bucket_players:${currentBucket}`, license);
            await redisClient.del(`player_location:${license}`);
        }
    }

    async processTelemetry(playerList) {
    const DENSITY_THRESHOLD = 25; 
    const SHARD_RADIUS = 100.0;   

    const mainRpPlayers = playerList.filter(p => p.bucket === 1);

    for (let i = 0; i < mainRpPlayers.length; i++) {
        let nearby = [mainRpPlayers[i]];

        for (let j = i + 1; j < mainRpPlayers.length; j++) {
            const p1 = mainRpPlayers[i];
            const p2 = mainRpPlayers[j];

            const dist = Math.sqrt(
                Math.pow(p2.x - p1.x, 2) + 
                Math.pow(p2.y - p1.y, 2) + 
                Math.pow(p2.z - p1.z, 2)
            );

            if (dist <= SHARD_RADIUS) {
                nearby.push(p2);
            }
        }

        if (nearby.length > DENSITY_THRESHOLD) {
            const shardBucketId = 1001;
            const playersToMove = nearby.slice(Math.floor(nearby.length / 2));

            for (const player of playersToMove) {
                await this.assignPlayerToBucket(player.license, shardBucketId);
                const payload = JSON.stringify({ license: player.license, bucket: shardBucketId });
                await this.redisPublisher.publish('queue_transfer_ready', payload);
            }
            break;
        }
    }
}
    
    async broadcastAnnouncement(message) {
        const payload = JSON.stringify({ author: "System", text: message, type: "announcement" });
        await redisPublisher.publish('system_announcement', payload);
    }
}



module.exports = new GlobalStateManager();