const Redis = require('ioredis');
const StateManager = require('./state-manager');

const redisQueue = new Redis({ host: '172.17.33.10', port: 6379 });

class QueueManager {
    constructor() {
        this.activeQueues = new Set();
        this.startQueueWorker();
    }

    
    async enqueuePlayer(license, targetBucket, priority = 0) {
        const queueKey = `queue:bucket_${targetBucket}:priority_${priority}`;
        
        
        await redisQueue.rpush(queueKey, license);
        this.activeQueues.add(targetBucket);

        
        const position = await redisQueue.llen(queueKey);
        return { queued: true, position: position, bucket: targetBucket };
    }

    
    startQueueWorker() {
        setInterval(async () => {
            for (const bucket of this.activeQueues) {
                
                const currentPlayers = await StateManager.redisClient.scard(`bucket_players:${bucket}`);
                
                if (currentPlayers < StateManager.BUCKET_CAPACITY) {
                    
                    const license = await redisQueue.lpop(`queue:bucket_${bucket}:priority_1`) || 
                                    await redisQueue.lpop(`queue:bucket_${bucket}:priority_0`);

                    if (license) {
                        
                        await StateManager.assignPlayerToBucket(license, bucket);
                        
                        
                        
                        const payload = JSON.stringify({ license, bucket });
                        await StateManager.redisPublisher.publish('queue_transfer_ready', payload);
                    } else {
                        
                        this.activeQueues.delete(bucket);
                    }
                }
            }
        }, 3000);
    }
}

module.exports = new QueueManager();