import OpenAI from "openai";
import dotenv from "dotenv";
import { getProcurementData } from "./procurementService.js";

dotenv.config();

const openai = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY,
});

export const generateAIResponse = async (userMessage) => {

  // Example: Attach procurement data to AI context
  const procurementData = getProcurementData();

  const completion = await openai.chat.completions.create({
    model: "gpt-4o-mini",
    messages: [
      {
        role: "system",
        content: `
        You are BuildAssist AI, an intelligent assistant 
        for construction procurement management.

        Here is current procurement data:
        ${JSON.stringify(procurementData)}
        `,
      },
      {
        role: "user",
        content: userMessage,
      },
    ],
  });

  return completion.choices[0].message.content;
};