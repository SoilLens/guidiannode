require('dotenv').config();
const express = require('express');
const cors = require('cors');

const { logAuthModeBanner } = require('./config/authConfig');
const authRoutes = require('./routes/authRoutes');
const alertRoutes = require('./routes/alertRoutes');
const locationRoutes = require('./routes/locationRoutes');
const profileRoutes = require('./routes/profileRoutes');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());

// Routes
// SUPER BACKEND PROMPT specifies /api/auth/... for these endpoints
app.use('/api/auth', authRoutes);
app.use('/api/location', locationRoutes);
app.use('/api/alerts', alertRoutes);
app.use('/api/profile', profileRoutes);

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'ok', message: 'GuardianNode Backend is running' });
});

logAuthModeBanner();

// Start Server
app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
});
