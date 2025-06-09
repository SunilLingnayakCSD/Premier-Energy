/* @RestResource(urlMapping='/sapCustomerData/*')
global with sharing class SAPCustomerDataController {

    @HttpPost
    global static void processCustomerData() {
        RestRequest request = RestContext.request;
        RestResponse response = RestContext.response;

        try {
            String requestBody = request.requestBody.toString();
            System.debug('Received Body: ' + requestBody);

            Object rawData = JSON.deserializeUntyped(requestBody);

            if (!(rawData instanceof List<Object>)) {
                response.statusCode = 400;
                response.responseBody = Blob.valueOf(JSON.serialize(new Map<String, Object>{
                    'status' => 'error',
                    'message' => 'Request body must be a JSON array of customer objects.'
                }));
                return;
            }

            List<Object> customerListRaw = (List<Object>) rawData;
            List<Account> accountsToInsert = new List<Account>();
            Map<String, Map<String, Object>> rawCustomerMap = new Map<String, Map<String, Object>>();

            // Step 1: Build Accounts
            for (Object customerObj : customerListRaw) {
                Map<String, Object> customer = (Map<String, Object>) customerObj;

                String customerCode = (String) customer.get('Customer_Code__c');
                rawCustomerMap.put(customerCode, customer);

                Account acc = new Account();
                acc.Customer_Code__c = customerCode;
                acc.Name = (String) customer.get('Name');
                acc.Customer_Deletion_Check__c = (String) customer.get('Customer_Deletion_Check__c');
                acc.Customer_GST_Number__c = (String) customer.get('Customer_GST_Number__c');
                accountsToInsert.add(acc);
            }

            if (accountsToInsert.isEmpty()) {
                response.statusCode = 400;
                response.responseBody = Blob.valueOf(JSON.serialize(new Map<String, String>{
                    'status' => 'error',
                    'message' => 'No customer data provided'
                }));
                return;
            }

            // Step 2: Insert Accounts
            insert accountsToInsert;

            Map<String, Id> customerCodeToAccountId = new Map<String, Id>();
            for (Account acc : accountsToInsert) {
                customerCodeToAccountId.put(acc.Customer_Code__c, acc.Id);
            }

            // Step 3: Build Address Records
            List<Address__c> addressesToInsert = new List<Address__c>();

            for (String custCode : rawCustomerMap.keySet()) {
                Map<String, Object> customer = rawCustomerMap.get(custCode);
                if (customer.containsKey('Address__c') && customer.get('Address__c') instanceof List<Object>) {
                    List<Object> addressList = (List<Object>) customer.get('Address__c');

                    for (Object addrObj : addressList) {
                        Map<String, Object> addr = (Map<String, Object>) addrObj;

                        Address__c address = new Address__c();
                        address.Customer_Code__c = custCode;
                        address.Account__c = customerCodeToAccountId.get(custCode);

                        address.Address_Type__c = (String) addr.get('Address_Type__c');
                        address.Street__c = (String) addr.get('Street__c');
                        address.City__c = (String) addr.get('City__c');
                        address.Pincode__c = Decimal.valueOf((String) addr.get('Pincode__c'));
                        address.State__c = (String) addr.get('State__c');
                        address.Country__c = (String) addr.get('Country__c');

                        addressesToInsert.add(address);
                    }
                }
            }

            if (!addressesToInsert.isEmpty()) {
                insert addressesToInsert;
            }

            response.statusCode = 200;
            response.responseBody = Blob.valueOf(JSON.serialize(new Map<String, Object>{
                'status' => 'success',
                'message' => 'Customer and address records created successfully.',
                'accountsCreated' => accountsToInsert.size(),
                'addressesCreated' => addressesToInsert.size()
            }));

        } catch (Exception e) {
            response.statusCode = 500;
            response.responseBody = Blob.valueOf(JSON.serialize(new Map<String, Object>{
                'status' => 'error',
                'message' => 'Exception occurred: ' + e.getMessage()
            }));

           
        }
    }
}*/

@RestResource(urlMapping='/sapCustomerData/*')
global with sharing class SAPCustomerDataController {

    @HttpPost
    global static void processCustomerData() {
        RestRequest request = RestContext.request;
        RestResponse response = RestContext.response;

        try {
            String requestBody = request.requestBody.toString();
            System.debug('Received Body: ' + requestBody);

            Object rawData = JSON.deserializeUntyped(requestBody);

            // Unwrap 'root' key if it exists
            if (rawData instanceof Map<String, Object>) {
                Map<String, Object> rootMap = (Map<String, Object>) rawData;
                if (rootMap.containsKey('root') && rootMap.get('root') instanceof List<Object>) {
                    rawData = rootMap.get('root');
                } else {
                    response.statusCode = 400;
                    response.responseBody = Blob.valueOf(JSON.serialize(new Map<String, Object>{
                        'status' => 'error',
                        'message' => 'Missing or invalid "root" key with customer data array.'
                    }));
                    return;
                }
            }

            if (!(rawData instanceof List<Object>)) {
                response.statusCode = 400;
                response.responseBody = Blob.valueOf(JSON.serialize(new Map<String, Object>{
                    'status' => 'error',
                    'message' => 'Request body must be a JSON array of customer objects.'
                }));
                return;
            }

            List<Object> customerListRaw = (List<Object>) rawData;
            List<Account> accountsToInsert = new List<Account>();
            Map<String, Map<String, Object>> rawCustomerMap = new Map<String, Map<String, Object>>();

            // Step 1: Build Account records
            for (Object customerObj : customerListRaw) {
                Map<String, Object> customer = (Map<String, Object>) customerObj;

                String customerCode = (String) customer.get('Customer_Code__c');
                rawCustomerMap.put(customerCode, customer);

                Account acc = new Account();
                acc.Customer_Code__c = customerCode;
                acc.Name = (String) customer.get('Name');
                acc.Customer_Deletion_Check__c = (String) customer.get('Customer_Deletion_Check__c');
                acc.Customer_GST_Number__c = (String) customer.get('Customer_GST_Number__c');
                accountsToInsert.add(acc);
            }

            if (accountsToInsert.isEmpty()) {
                response.statusCode = 400;
                response.responseBody = Blob.valueOf(JSON.serialize(new Map<String, String>{
                    'status' => 'error',
                    'message' => 'No customer data provided'
                }));
                return;
            }

            insert accountsToInsert;

            Map<String, Id> customerCodeToAccountId = new Map<String, Id>();
            for (Account acc : accountsToInsert) {
                customerCodeToAccountId.put(acc.Customer_Code__c, acc.Id);
            }

            // Step 2: Build Address records
            List<Address__c> addressesToInsert = new List<Address__c>();

            for (String custCode : rawCustomerMap.keySet()) {
                Map<String, Object> customer = rawCustomerMap.get(custCode);

                if (customer.containsKey('Address__c') && customer.get('Address__c') instanceof List<Object>) {
                    List<Object> addressList = (List<Object>) customer.get('Address__c');

                    for (Object addrObj : addressList) {
                        Map<String, Object> addr = (Map<String, Object>) addrObj;

                        Address__c address = new Address__c();
                        address.Customer_Code__c = custCode;
                        address.Account__c = customerCodeToAccountId.get(custCode);
                        address.Address_Type__c = (String) addr.get('Address_Type__c');
                        address.Street__c = (String) addr.get('Street__c');
                        address.City__c = (String) addr.get('City__c');
                        address.Pincode__c = Decimal.valueOf((String) addr.get('Pincode__c'));
                        address.State__c = (String) addr.get('State__c');
                        address.Country__c = (String) addr.get('Country__c');

                        addressesToInsert.add(address);
                    }
                }
            }

            if (!addressesToInsert.isEmpty()) {
                insert addressesToInsert;
            }

            // Final response
            response.statusCode = 200;
            response.responseBody = Blob.valueOf(JSON.serialize(new Map<String, Object>{
                'status' => 'success',
                'message' => 'Customer and address records created successfully.',
                'accountsCreated' => accountsToInsert.size(),
                'addressesCreated' => addressesToInsert.size()
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