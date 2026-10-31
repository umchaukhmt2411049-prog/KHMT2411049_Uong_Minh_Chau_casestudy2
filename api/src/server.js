require("dotenv").config();

const app = require("./app");
const connectDB = require("./config/database");

async function startServer() {
  try {
    // Ket noi MongoDB truoc khi mo server
    await connectDB();

    const port = Number(process.env.PORT) || 3000;

    app.listen(port, () => {
      console.log(`Server running at http://localhost:${port}`);
    });
  } catch (error) {
    console.error("Server startup error:", error.message);
    process.exit(1);
  }
}

startServer();