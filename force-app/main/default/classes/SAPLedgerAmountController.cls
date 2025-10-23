@RestResource(urlMapping='/updateLedgerBalance/*')
global without sharing class SAPLedgerAmountController {

    @HttpPost
    global static void runLedgerBatch() {
        try {
            // Step 1: Read raw JSON from request
            String body = RestContext.request.requestBody.toString();

            // Step 2: Parse into wrapper objects
            List<LedgerBalanceUpdateBatch.LedgerWrapper> parsedList =
                LedgerBalanceUpdateBatch.parseJson(body);

            // Step 3: Launch batch with a safe scope size
            Database.executeBatch(new LedgerBalanceUpdateBatch(parsedList), 200);

            // Step 4: Respond with success
            RestContext.response.statusCode = 202;
            RestContext.response.responseBody = Blob.valueOf('{"status":"Success"}');

        } catch (Exception e) {
            // Optional: Log error to your custom exception handler
           // HandleCustomException.LogException(e);

            RestContext.response.statusCode = 500;
            RestContext.response.responseBody = Blob.valueOf(
                JSON.serialize(new Map<String, Object>{
                    'status'  => 'error',
                    'message' => e.getMessage()
                })
            );
        }
    }
}