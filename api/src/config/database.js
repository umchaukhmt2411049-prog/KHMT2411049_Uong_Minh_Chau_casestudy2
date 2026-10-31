const mongoose = require("mongoose");

async function connectDB() {
  const uri = process.env.MONGODB_URI;

  if (!uri) {
    console.error("Thieu MONGODB_URI trong file .env");
    process.exit(1);
  }

  try {
    await mongoose.connect(uri);
    console.log("MongoDB Atlas connected successfully!");
  } catch (error) {
    console.error("MongoDB connection error:", error.message);
    process.exit(1);
  }
}

module.exports = connectDB;