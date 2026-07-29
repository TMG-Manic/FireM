const express = require('express');
const crypto = require('crypto');
const Redis = require('ioredis');

const app = express();
const redis = new Redis({
  host: '172.17.33.10', 
  port: 6379
});
app.use(express.json());

const StateManager = require('./state-manager');


app.post('/internal/assign_bucket', async (req, res) => {
    const { license, targetBucket } = req.body;
    
    if (!license || targetBucket === undefined) {
        return res.status(400).json({ error: "Missing parameters" });
    }

    const assignment = await StateManager.assignPlayerToBucket(license, targetBucket);
    res.json(assignment);
});


app.post('/internal/player_dropped', async (req, res) => {
    const { license } = req.body;
    
    if (license) {
        await StateManager.removePlayer(license);
    }
    
    res.json({ success: true });
});


app.post('/internal/relay_chat', async (req, res) => {
    const { author, text, bucket } = req.body;
    
    const payload = JSON.stringify({ author, text, bucket });
    await StateManager.redisPublisher.publish('global_chat', payload);
    
    res.json({ success: true });
});


const QueueManager = require('./queue-manager');


app.get('/api/glist', async (req, res) => {
    const networkState = {};
    let totalPlayers = 0;

    
    const keys = await StateManager.redisClient.keys('bucket_players:*');
    
    for (const key of keys) {
        const bucketId = key.split(':')[1];
        const count = await StateManager.redisClient.scard(key);
        networkState[bucketId] = count;
        totalPlayers += count;
    }

    res.json({ total: totalPlayers, servers: networkState });
});


app.post('/api/find', async (req, res) => {
    const { targetLicense } = req.body;
    
    
    const bucket = await StateManager.redisClient.get(`player_location:${targetLicense}`);
    
    if (bucket) {
        res.json({ online: true, bucket: bucket });
    } else {
        res.json({ online: false });
    }
});

const SocialManager = require('./social-manager');


app.post('/api/social/msg', async (req, res) => {
    const { senderLicense, senderName, targetLicense, message } = req.body;
    const result = await SocialManager.sendPrivateMessage(senderLicense, senderName, targetLicense, message);
    res.json(result);
});


app.post('/api/social/party', async (req, res) => {
    const { action, license, targetLicense, bucket } = req.body;

    try {
        if (action === 'create') {
            await SocialManager.createParty(license);
            res.json({ success: true });
        } else if (action === 'invite') {
            await SocialManager.inviteToParty(license, targetLicense);
            res.json({ success: true });
        } else if (action === 'accept') {
            const result = await SocialManager.acceptPartyInvite(license);
            res.json(result);
        } else if (action === 'warp') {
            const members = await SocialManager.warpParty(license, bucket);
            res.json({ success: true, count: members.length });
        }
    } catch (err) {
        res.status(500).json({ success: false, reason: "Internal server error." });
    }
});
const GATEWAY_PORT = 3000;
const TOKEN_TTL_SECONDS = 30;


app.post('/api/request_connection', async (req, res) => {
    const { license, targetServerId } = req.body;

    if (!license || !targetServerId) {
        return res.status(400).json({ error: "Missing required parameters." });
    }

    
    const connectionToken = crypto.randomBytes(32).toString('hex');
    
    
    const payload = JSON.stringify({ license, bucket: targetServerId });
    await redis.set(`auth_token:${connectionToken}`, payload, 'EX', TOKEN_TTL_SECONDS);

    
    res.json({ success: true, token: connectionToken });
});


app.post('/internal/validate_token', async (req, res) => {
    const { token, license } = req.body;

    const redisKey = `auth_token:${token}`;
    const storedData = await redis.get(redisKey);

    if (!storedData) {
        return res.status(401).json({ valid: false, reason: "Invalid or expired token." });
    }

    const parsedData = JSON.parse(storedData);

    
    if (parsedData.license !== license) {
        return res.status(401).json({ valid: false, reason: "License mismatch." });
    }

    
    await redis.del(redisKey);

    res.json({ valid: true, bucket: parsedData.bucket });
});

app.listen(GATEWAY_PORT, () => {
    console.log(`[Gateway] Master Dispatcher listening on port ${GATEWAY_PORT}`);
});