import { sendmail } from "../mail/ses";

export default {
  sendEmail: async (_, { to, title, body }, { user }) => {
    if (!user) return { status: 403, message: "no auth" };
    const result = await sendmail(to, title, body);
    return { status: 200, message: result };
  },
};
