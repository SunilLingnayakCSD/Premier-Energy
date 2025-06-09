@RestResource(urlMapping='/sapInvoiceData/*')
global without sharing class SAPInvoiceDataController {
    
   @HttpPost
    global static void processInvoiceData() {
        RestRequest request = RestContext.request;
        RestResponse response = RestContext.response;

        try {
            String requestBody = request.requestBody.toString();
            System.debug('Received Body: ' + requestBody);

            Object rawData = JSON.deserializeUntyped(requestBody);

            // Validate JSON structure
            if (!(rawData instanceof Map<String, Object>) || !((Map<String, Object>) rawData).containsKey('root')) {
                response.statusCode = 400;
                response.responseBody = Blob.valueOf(JSON.serialize(new Map<String, Object>{
                    'status' => 'error',
                    'message' => 'Missing or invalid "root" key with invoice data array.'
                }));
                return;
            }

            List<Object> invoiceList = (List<Object>) ((Map<String, Object>) rawData).get('root');
            if (invoiceList.isEmpty()) {
                response.statusCode = 400;
                response.responseBody = Blob.valueOf(JSON.serialize(new Map<String, Object>{
                    'status' => 'error',
                    'message' => 'No invoice data provided.'
                }));
                return;
            }

            // Step 1: Collect Order IDs
            Set<String> sapOrderIds = new Set<String>();
            for (Object invObj : invoiceList) {
                Map<String, Object> invoiceMap = (Map<String, Object>) invObj;
                if (invoiceMap.containsKey('OrderNumber')) {
                    sapOrderIds.add((String) invoiceMap.get('OrderNumber'));
                }
            }

            // Step 2: Query Order__c records and map to Account Ids
            Map<String, Id> orderIdToAccountIdMap = new Map<String, Id>();
            for (Order order : [
                SELECT Id, OrderNumber, AccountId
                FROM Order
                WHERE OrderNumber IN :sapOrderIds
            ]) {
                orderIdToAccountIdMap.put(order.OrderNumber, order.AccountId);
            }

            // Step 3: Build Invoice__c records
            List<Invoice__c> invoicesToInsert = new List<Invoice__c>();

            for (Object invObj : invoiceList) {
                Map<String, Object> invoiceMap = (Map<String, Object>) invObj;

                String sapOrderId = (String) invoiceMap.get('OrderNumber');
                Id accId = orderIdToAccountIdMap.get(sapOrderId);

                if (accId == null) {
                    throw new AuraHandledException('No matching Account found for Order_Id__c: ' + sapOrderId);
                }

                Invoice__c invoice = new Invoice__c();
                invoice.Account__c = accId;
                invoice.Invoice_Number__c = (String) invoiceMap.get('Invoice_Number__c');

                // Date parsing (optional field handling)
                String rawDate = (String) invoiceMap.get('Invoice_Date__c');
                if (!String.isBlank(rawDate)) {
                    invoice.Invoice_Date__c = Date.valueOf(rawDate.trim());
                }

                invoice.Delivery_Number__c = (String) invoiceMap.get('Delivery_Number__c');
                invoice.Material_Number__c = (String) invoiceMap.get('Material_Number__c');
                invoice.Material_Description__c = (String) invoiceMap.get('Material_Description__c');
                invoice.HSN_Code__c = (String) invoiceMap.get('HSN_Code__c');
                invoice.Quantity__c = (String) invoiceMap.get('Quantity__c');
                invoice.Quantity_Unit__c = (String) invoiceMap.get('Quantity_Unit__c');
                invoice.Amount__c = Decimal.valueOf((String) invoiceMap.get('Amount__c'));
                invoice.Amount_Currency__c = Decimal.valueOf((String) invoiceMap.get('Amount_Currency__c'));
                invoice.Less_Discount__c = (String) invoiceMap.get('Less_Discount__c');
                invoice.Tax_Value__c = (String) invoiceMap.get('Tax_Value__c');
                invoice.CGST__c = (String) invoiceMap.get('CGST__c');
                invoice.SGST__c = (String) invoiceMap.get('SGST__c');
                invoice.IGST__c = (String) invoiceMap.get('IGST__c');
                invoice.Total_Invoice_Value__c = (String) invoiceMap.get('Total_Invoice_Value__c');

                invoicesToInsert.add(invoice);
            }

            // Step 4: Insert Invoices
            insert invoicesToInsert;

            response.statusCode = 200;
            response.responseBody = Blob.valueOf(JSON.serialize(new Map<String, Object>{
                'status' => 'success',
                'message' => 'Invoice records created successfully.',
                'invoicesCreated' => invoicesToInsert.size()
            }));

        } catch (Exception e) {
            response.statusCode = 500;
            response.responseBody = Blob.valueOf(JSON.serialize(new Map<String, Object>{
                'status' => 'error',
                'message' => 'Exception occurred: ' + e.getMessage()
            }));
        }
    }
}