import { sendmail } from "../mail/ses";

export default {
  sendEmail: async (_, { to, title, body }) => {
    const result = await sendmail(to, title, body);
    console.log("result", result);
    return "mutation test";
  },
};
