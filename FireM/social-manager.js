const Redis = require('ioredis');
const StateManager = require('./state-manager');
const QueueManager = require('./queue-manager');

const redisClient = new Redis({ host: '172.17.33.10', port: 6379 });
class SocialManager {
    
    
    
    async sendPrivateMessage(senderLicense, senderName, targetLicense, message) {
        const targetBucket = await redisClient.get(`player_location:${targetLicense}`);
        
        if (!targetBucket) {
            return { success: false, reason: "Player is offline." };
        }

        
        await redisClient.set(`last_message:${targetLicense}`, senderLicense, 'EX', 3600);

        
        const payload = JSON.stringify({ 
            type: 'private_message',
            sender: senderName, 
            target: targetLicense, 
            text: message, 
            bucket: targetBucket 
        });
        await StateManager.redisPublisher.publish('system_announcement', payload);

        return { success: true, targetBucket };
    }

    async getReplyTarget(license) {
        return await redisClient.get(`last_message:${license}`);
    }

    
    
    
    async createParty(leaderLicense) {
        const partyId = `party:${leaderLicense}`;
        await redisClient.sadd(partyId, leaderLicense);
        await redisClient.expire(partyId, 86400); 
        return partyId;
    }

    async inviteToParty(leaderLicense, targetLicense) {
        
        await redisClient.set(`party_invite:${targetLicense}`, leaderLicense, 'EX', 60);
        return true;
    }

    async acceptPartyInvite(targetLicense) {
        const leaderLicense = await redisClient.get(`party_invite:${targetLicense}`);
        if (!leaderLicense) return { success: false, reason: "No active invites." };

        const partyId = `party:${leaderLicense}`;
        const exists = await redisClient.exists(partyId);
        
        if (!exists) return { success: false, reason: "Party no longer exists." };

        await redisClient.sadd(partyId, targetLicense);
        await redisClient.del(`party_invite:${targetLicense}`);

        
        const leaderBucket = await redisClient.get(`player_location:${leaderLicense}`);
        
        return { success: true, partyId, bucket: leaderBucket, leader: leaderLicense };
    }

    async warpParty(leaderLicense, targetBucket) {
        const partyId = `party:${leaderLicense}`;
        const members = await redisClient.smembers(partyId);

        if (!members || members.length === 0) return false;

        
        for (const member of members) {
            await QueueManager.enqueuePlayer(member, targetBucket, 1); 
        }

        return members;
    }
}

module.exports = new SocialManager();