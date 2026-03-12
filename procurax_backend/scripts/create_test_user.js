import mongoose from 'mongoose';
import User from '../models/User.js';
import '../config/env.js';

async function main() {
  const mongoUri = process.env.MONGODB_URI || process.env.MONGO_URI || 'mongodb://127.0.0.1:27017/procurax';
  await mongoose.connect(mongoUri);

  const email = 'testuser@example.com';
  let user = await User.findOne({ email });
  if (!user) {
    user = new User({
      name: 'Test User',
      email,
      password: 'password',
      isApproved: true,
      isActive: true,
      role: 'project_manager',
    });
    await user.save();
    console.log('Created user', user._id.toString());
  } else {
    user.isApproved = true;
    user.isActive = true;
    await user.save();
    console.log('Updated user', user._id.toString());
  }

  await mongoose.disconnect();
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
