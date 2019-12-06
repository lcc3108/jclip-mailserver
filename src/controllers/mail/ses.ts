import aws from "aws-sdk";
import nodemailer, { SentMessageInfo } from "nodemailer";

const transporter = nodemailer.createTransport({
  SES: new aws.SES({
    accessKeyId: process.env.AWS_ACCESSKEY,
    secretAccessKey: process.env.AWS_SCERETKEY,
    region: "us-east-1",
    apiVersion: "2010-12-01",
  }),
});

export const sendmail = (to: string[], title: string, body: string): Promise<SentMessageInfo> => {
  return transporter.sendMail({
    from: "alarmbot@jclip.cf",
    to: to,
    subject: title,
    text: body,
  });
};
