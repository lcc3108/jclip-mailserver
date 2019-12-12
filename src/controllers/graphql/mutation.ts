import { sendmail } from "../mail/ses";

export default {
  sendEmail: async (_, { to, title, body }, { user }) => {
    if (!user) return "no auth";
    const result = await sendmail(to, title, body);
    return result;
  },
};
