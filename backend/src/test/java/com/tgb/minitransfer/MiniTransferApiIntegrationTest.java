package com.tgb.minitransfer;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.condition.EnabledIfEnvironmentVariable;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.data.mongodb.core.MongoTemplate;
import org.springframework.http.MediaType;
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;

import static org.hamcrest.Matchers.is;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * End-to-end test of the REST API through the full Spring stack (controllers + security +
 * services + Spring Data MongoDB) using {@link MockMvc} — no embedded web server is started.
 *
 * <p>Requires a MongoDB reachable at localhost:27017. It is therefore <b>opt-in</b>: it only runs
 * when the environment variable {@code IT_MONGO_ENABLED=true} is set (otherwise it is skipped),
 * so a plain {@code mvn test} stays self-contained and offline. Run it with:</p>
 * <pre>
 *   IT_MONGO_ENABLED=true mvn test -Dtest=MiniTransferApiIntegrationTest
 * </pre>
 */
@SpringBootTest
@AutoConfigureMockMvc
@TestPropertySource(properties = {
        "spring.data.mongodb.uri=mongodb://localhost:27017/minitransfer_it_test",
        "app.jwt.secret=integration-test-secret-integration-test-secret-0123456789",
        "app.jwt.expiration-ms=86400000",
        "app.wallet.initial-balance=10000"
})
@EnabledIfEnvironmentVariable(named = "IT_MONGO_ENABLED", matches = "true")
class MiniTransferApiIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private MongoTemplate mongoTemplate;

    @Autowired
    private ObjectMapper objectMapper;

    @BeforeEach
    void cleanDatabase() {
        // Isolate every test with a fresh database.
        mongoTemplate.getDb().drop();
    }

    private String register(String name, String email, String phone, String password) throws Exception {
        MvcResult result = mockMvc.perform(post("/api/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"name":"%s","email":"%s","phone":"%s","password":"%s"}
                                """.formatted(name, email, phone, password)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.user.balance", is(10000)))
                .andReturn();
        return objectMapper.readTree(result.getResponse().getContentAsString()).get("token").asText();
    }

    @Test
    void fullTransferFlow_movesMoneyConsistently() throws Exception {
        String aliceToken = register("Alice", "alice@example.com", "+237600000001", "secret123");
        String bobToken = register("Bob", "bob@example.com", "+237600000002", "secret123");

        // Alice starts with the demo balance.
        mockMvc.perform(get("/api/wallet/balance").header("Authorization", "Bearer " + aliceToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.balance", is(10000)))
                .andExpect(jsonPath("$.currency", is("FCFA")));

        // Alice sends 2500 FCFA to Bob.
        mockMvc.perform(post("/api/transfers")
                        .header("Authorization", "Bearer " + aliceToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"recipient":"bob@example.com","amount":2500}
                                """))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.transaction.status", is("COMPLETED")))
                .andExpect(jsonPath("$.transaction.direction", is("SENT")))
                .andExpect(jsonPath("$.newBalance", is(7500)));

        // Money is conserved: Alice 7500, Bob 12500.
        mockMvc.perform(get("/api/wallet/balance").header("Authorization", "Bearer " + aliceToken))
                .andExpect(jsonPath("$.balance", is(7500)));
        mockMvc.perform(get("/api/wallet/balance").header("Authorization", "Bearer " + bobToken))
                .andExpect(jsonPath("$.balance", is(12500)));

        // History reflects both points of view.
        mockMvc.perform(get("/api/transfers/history").header("Authorization", "Bearer " + aliceToken))
                .andExpect(jsonPath("$.length()", is(1)))
                .andExpect(jsonPath("$[0].direction", is("SENT")))
                .andExpect(jsonPath("$[0].counterpartyEmail", is("bob@example.com")));
        mockMvc.perform(get("/api/transfers/history").header("Authorization", "Bearer " + bobToken))
                .andExpect(jsonPath("$[0].direction", is("RECEIVED")))
                .andExpect(jsonPath("$[0].counterpartyEmail", is("alice@example.com")));
    }

    @Test
    void rejectsInsufficientBalance() throws Exception {
        String aliceToken = register("Alice", "alice@example.com", "+237600000001", "secret123");
        register("Bob", "bob@example.com", "+237600000002", "secret123");

        mockMvc.perform(post("/api/transfers")
                        .header("Authorization", "Bearer " + aliceToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"recipient":"bob@example.com","amount":99999999}
                                """))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code", is("INSUFFICIENT_BALANCE")));
    }

    @Test
    void rejectsSelfTransfer() throws Exception {
        String aliceToken = register("Alice", "alice@example.com", "+237600000001", "secret123");

        mockMvc.perform(post("/api/transfers")
                        .header("Authorization", "Bearer " + aliceToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"recipient":"alice@example.com","amount":1000}
                                """))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code", is("SELF_TRANSFER")));
    }

    @Test
    void rejectsUnknownRecipient() throws Exception {
        String aliceToken = register("Alice", "alice@example.com", "+237600000001", "secret123");

        mockMvc.perform(post("/api/transfers")
                        .header("Authorization", "Bearer " + aliceToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"recipient":"ghost@example.com","amount":1000}
                                """))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.code", is("RECIPIENT_NOT_FOUND")));
    }

    @Test
    void rejectsNonPositiveAmount() throws Exception {
        String aliceToken = register("Alice", "alice@example.com", "+237600000001", "secret123");

        mockMvc.perform(post("/api/transfers")
                        .header("Authorization", "Bearer " + aliceToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"recipient":"bob@example.com","amount":-50}
                                """))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code", is("VALIDATION_ERROR")));
    }

    @Test
    void rejectsUnauthenticatedAccess() throws Exception {
        mockMvc.perform(get("/api/wallet/balance"))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.code", is("UNAUTHENTICATED")));
    }

    @Test
    void rejectsDuplicateEmail() throws Exception {
        register("Alice", "alice@example.com", "+237600000001", "secret123");

        mockMvc.perform(post("/api/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"name":"Alice 2","email":"alice@example.com","phone":"+237600000009","password":"secret123"}
                                """))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.code", is("EMAIL_TAKEN")));
    }

    @Test
    void rejectsWrongPassword() throws Exception {
        register("Alice", "alice@example.com", "+237600000001", "secret123");

        mockMvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"email":"alice@example.com","password":"wrong-password"}
                                """))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.code", is("BAD_CREDENTIALS")));
    }
}
