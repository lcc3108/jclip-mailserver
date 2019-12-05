import { resolvers } from "@/controllers/graphql/resolvers";
import { schemaDirectives } from "@/models/graphql/directives";
import { typeDefs } from "@/models/graphql/types";
import { ApolloServer } from "apollo-server-express";

const server = new ApolloServer({
  typeDefs,
  resolvers,
  context: ({ req }) => ({ user: req["user"] }),
  schemaDirectives,
});

export default server;
