import { ApolloServer, gql } from "apollo-server-cloud-functions";
import { typeDefs } from "@/models/graphql/types";
import { resolvers } from "@/controllers/graphql/resolvers";
import jwt from "jsonwebtoken";

export const gcpServer = new ApolloServer({
  typeDefs,
  resolvers,
  context: ({ req }) => {
    if (!req.headers.authorization) {
      console.log("no header");
      return { user: undefined };
    }

    const token = req.headers.authorization.substr(7);
    console.log("token", token);
    try {
      const user = jwt.verify(token, process.env.JWT_SECRET, (err, payload) => {
        console.log("err", err);
        console.log("payload", payload);
      });
      console.log("yes verify");

      return { user };
    } catch {
      console.log("no verify");

      return { user: undefined };
    }
  },
  // playground: false,
  // introspection: false,
});
gcpServer.setGraphQLPath("/");
