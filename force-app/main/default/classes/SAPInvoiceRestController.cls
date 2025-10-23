@RestResource(urlMapping='/sapInvoiceData/*')
global without sharing class SAPInvoiceRestController {
    @HttpPost
    global static void runBatch() {
        try {
            String body = RestContext.request.requestBody.toString();
            List<SAPInvoiceBatchController.InvoiceWrapper> parsedList = SAPInvoiceBatchController.parseJson(body);
            Database.executeBatch(new SAPInvoiceBatchController(parsedList), 200);
            RestContext.response.statusCode = 202;
            RestContext.response.responseBody = Blob.valueOf('{"status":"Success"}');
        } catch (Exception e) {
           HandleCustomException.LogException(e);

            System.debug('********'+e);
            RestContext.response.statusCode = 500;
            RestContext.response.responseBody = Blob.valueOf(
                JSON.serialize(new Map<String, Object>{
                    'status' => 'error',
                    'message' => e.getMessage()
                })
            );
        }
    }
}