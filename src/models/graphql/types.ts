import { gql } from "apollo-server-lambda";

export const typeDefs = gql`
  type Response {
    status: Int!
    message: String!
  }
  type Query {
    query_test: String
  }
  type Mutation {
    sendEmail(to: String, title: String, body: String): Response!
  }
`;
