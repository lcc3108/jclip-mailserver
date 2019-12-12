import { gql } from "apollo-server-lambda";

export const typeDefs = gql`
  directive @isAuth on FIELD_DEFINITION

  type Response {
    status: Int!
    message: String!
  }
  type Query {
    query_test: String
  }
  type Mutation {
    sendEmail(to: String, title: String, body: String): Response! @isAuth
  }
`;
