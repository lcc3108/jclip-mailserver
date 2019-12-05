import { requestGraphQLAsync } from "@/test/http";
import { expect } from "chai";

describe("query test", () => {
  it("gql query call", async () => {
    const result = await requestGraphQLAsync({ query: "query{ query_test }" });
    expect(result.text).to.have.string("pong");
  });
});

// https://www.chaijs.com/plugins/chai-http/
