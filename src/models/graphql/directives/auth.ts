import { SchemaDirectiveVisitor } from "apollo-server-cloud-functions";
import { defaultFieldResolver } from "graphql";

export class IsAuthDirective extends SchemaDirectiveVisitor {
  public visitFieldDefinition(field) {
    const { resolve = defaultFieldResolver } = field;
    field.resolve = async function(...args) {
      const [, {}, { user }] = args;
      if (!user) {
        throw new Error("User not authenticated");
      }
      // args[2].authUser = authUser;
      return resolve.apply(this, args);
    };
  }
}
