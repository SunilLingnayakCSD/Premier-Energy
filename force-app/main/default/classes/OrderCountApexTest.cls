@IsTest
private class orderCountApexTest {

    @TestSetup
    static void setupTestData() {
        // 1. Create Account
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        // 2. Create Contact
        Contact con = new Contact(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'testuser@example.com',
            AccountId = acc.Id
        );
        insert con;

        // 3. Get a Profile for the new User
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Partner Distributor Access' LIMIT 1];

        // 4. Create a User and assign ContactId
        User testUser = new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'testuser@example.com',
            Username = 'testuser' + DateTime.now().getTime() + '@example.com',
            Alias = 'tuser',
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = p.Id,
            ContactId = con.Id
        );
        insert testUser;

        // Create orders and invoices as system admin to avoid permission issues
        System.runAs(new User(Id = UserInfo.getUserId())) {
            // 5. Get RecordTypeId for 'Purchase Order'
            Id recordTypeId;
            try {
                if (Schema.SObjectType.Order.getRecordTypeInfosByName().containsKey('Purchase Order')) {
                    recordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByName().get('Purchase Order').getRecordTypeId();
                } else {
                    recordTypeId = null; // fallback if not found
                }
            } catch (Exception e) {
                recordTypeId = null;
            }

            // 6. Create 4 Orders (each with different scenario to test the classification logic)
            List<Order> orders = new List<Order>();

            // Order 1: Cancelled (Rejected) - should increment 'cancelled' counter
            orders.add(new Order(
                AccountId = acc.Id,
                EffectiveDate = System.today(),
                Status = 'Draft',
                Type__c = 'Channel Sales',
                Approval_Status__c = 'Rejected', // This should trigger cancelled classification
                RecordTypeId = recordTypeId,
                Wattage_Wp_Cell_Module1__c = '540.00',
                Product_Details_Technology_Type__c = 'MONOPERC_MONOFACIAL-M10',
                DCR_Non_DCR1__c = 'DCR',
                Segment1__c = 'CELL_DOMESTIC',
                Domestic_Exports__c = 'Domestic',
                Product_Category__c = 'CELL',
                TotalQuantity__c = '1340',
                Premier_Business_Entity1__c = 'PEL',
                Plant_Store_Name__c = 'PEL - ANNARAM PLANT',
                Delivery_required_by__c = System.today().addDays(7),
                Total_Capacity_in_MWp__c = 0.40
            ));

            // Order 2: Closed (POD Uploaded) - should increment 'closed' counter
            orders.add(new Order(
                AccountId = acc.Id,
                EffectiveDate = System.today(),
                Status = 'Draft',
                Type__c = 'Channel Sales',
                Approval_Status__c = 'Approved', // Not rejected
                RecordTypeId = recordTypeId,
                Wattage_Wp_Cell_Module1__c = '540.00',
                Product_Details_Technology_Type__c = 'MONOPERC_MONOFACIAL-M10',
                DCR_Non_DCR1__c = 'DCR',
                Segment1__c = 'CELL_DOMESTIC',
                Domestic_Exports__c = 'Domestic',
                Product_Category__c = 'CELL',
                TotalQuantity__c = '1340',
                Premier_Business_Entity1__c = 'PEL',
                Plant_Store_Name__c = 'PEL - ANNARAM PLANT',
                Delivery_required_by__c = System.today().addDays(7),
                Total_Capacity_in_MWp__c = 0.40
            ));

            // Order 3: In Transit (POD Not Uploaded) - should increment 'intransit' counter
            orders.add(new Order(
                AccountId = acc.Id,
                EffectiveDate = System.today(),
                Status = 'Draft',
                Type__c = 'Channel Sales',
                Approval_Status__c = 'Approved', // Not rejected
                RecordTypeId = recordTypeId,
                Wattage_Wp_Cell_Module1__c = '540.00',
                Product_Details_Technology_Type__c = 'MONOPERC_MONOFACIAL-M10',
                DCR_Non_DCR1__c = 'DCR',
                Segment1__c = 'CELL_DOMESTIC',
                Domestic_Exports__c = 'Domestic',
                Product_Category__c = 'CELL',
                TotalQuantity__c = '1340',
                Premier_Business_Entity1__c = 'PEL',
                Plant_Store_Name__c = 'PEL - ANNARAM PLANT',
                Delivery_required_by__c = System.today().addDays(7),
                Total_Capacity_in_MWp__c = 0.40
            ));

            // Order 4: In Progress (No invoices) - should increment 'inprogress' counter
            orders.add(new Order(
                AccountId = acc.Id,
                EffectiveDate = System.today(),
                Status = 'Draft',
                Type__c = 'Channel Sales',
                Approval_Status__c = 'Approved', // Not rejected
                RecordTypeId = recordTypeId,
                Wattage_Wp_Cell_Module1__c = '540.00',
                Product_Details_Technology_Type__c = 'MONOPERC_MONOFACIAL-M10',
                DCR_Non_DCR1__c = 'DCR',
                Segment1__c = 'CELL_DOMESTIC',
                Domestic_Exports__c = 'Domestic',
                Product_Category__c = 'CELL',
                TotalQuantity__c = '1340',
                Premier_Business_Entity1__c = 'PEL',
                Plant_Store_Name__c = 'PEL - ANNARAM PLANT',
                Delivery_required_by__c = System.today().addDays(7),
                Total_Capacity_in_MWp__c = 0.40
            ));

            // Order 5: Test multiple invoices with mixed POD statuses - should be classified as 'closed' (isClosed = true takes precedence)
            orders.add(new Order(
                AccountId = acc.Id,
                EffectiveDate = System.today(),
                Status = 'Draft',
                Type__c = 'Channel Sales',
                Approval_Status__c = 'Approved',
                RecordTypeId = recordTypeId,
                Wattage_Wp_Cell_Module1__c = '540.00',
                Product_Details_Technology_Type__c = 'MONOPERC_MONOFACIAL-M10',
                DCR_Non_DCR1__c = 'DCR',
                Segment1__c = 'CELL_DOMESTIC',
                Domestic_Exports__c = 'Domestic',
                Product_Category__c = 'CELL',
                TotalQuantity__c = '1340',
                Premier_Business_Entity1__c = 'PEL',
                Plant_Store_Name__c = 'PEL - ANNARAM PLANT',
                Delivery_required_by__c = System.today().addDays(7),
                Total_Capacity_in_MWp__c = 0.40
            ));

            insert orders;

            // 7. Create Invoices to test the classification logic
            List<Invoice__c> invoices = new List<Invoice__c>();

            // For Order 2: Create invoice with 'Uploaded' POD_Status (should make it 'closed')
            invoices.add(new Invoice__c(
                Order__c = orders[1].Id,
                POD_Status__c = 'Uploaded', // This triggers isClosed = true
                Account__c = acc.Id
            ));

            // For Order 3: Create invoice with 'Not Uploaded' POD_Status (should make it 'intransit')
            invoices.add(new Invoice__c(
                Order__c = orders[2].Id,
                POD_Status__c = 'Not Uploaded', // This triggers isInTransit = true
                Account__c = acc.Id
            ));

            // For Order 5: Create multiple invoices to test logic
            // First invoice with 'Not Uploaded'
            invoices.add(new Invoice__c(
                Order__c = orders[4].Id,
                POD_Status__c = 'Not Uploaded', // This would set isInTransit = true
                Account__c = acc.Id
            ));
            // Second invoice with 'Uploaded' - this should make isClosed = true and break the loop
            invoices.add(new Invoice__c(
                Order__c = orders[4].Id,
                POD_Status__c = 'Uploaded', // This sets isClosed = true and should break
                Account__c = acc.Id
            ));

            // Additional test cases for edge scenarios
            // Invoice with null POD_Status (should trigger isInTransit)
            invoices.add(new Invoice__c(
                Order__c = orders[2].Id, // Adding another invoice to order 3
                POD_Status__c = null, // null should trigger isInTransit = true
                Account__c = acc.Id
            ));

            // Invoice with 'None' POD_Status (should trigger isInTransit)
            invoices.add(new Invoice__c(
                Order__c = orders[2].Id, // Adding another invoice to order 3
                POD_Status__c = 'None', // 'None' should trigger isInTransit = true
                Account__c = acc.Id
            ));

            insert invoices;
        }
    }

    @IsTest
    static void testOrderMethod() {
        // Get the test user created in setup
        User testUser = [SELECT Id FROM User WHERE Email = 'testuser@example.com' AND IsActive = true LIMIT 1];
        
        // Run as the test user to test the method
        System.runAs(testUser) {
            Date startDate = System.today().addDays(-1);
            Date endDate = System.today().addDays(1);

            Test.startTest();
            Map<String, Integer> result = orderCountApex.orderMethod(startDate, endDate);
            Test.stopTest();

            System.debug('Result Map: ' + result);

            // Assertions based on the test data setup and classification logic
            System.assertNotEquals(null, result, 'Result should not be null');
            
            // Verify all expected keys exist
            System.assert(result.containsKey('cancelled'), 'Result should contain cancelled key');
            System.assert(result.containsKey('closed'), 'Result should contain closed key');
            System.assert(result.containsKey('intransit'), 'Result should contain intransit key');
            System.assert(result.containsKey('inprogress'), 'Result should contain inprogress key');

            // Test the classification logic based on our test data:
            // Order 1: Approval_Status__c = 'Rejected' -> cancelled
            System.assertEquals(1, result.get('cancelled'), 'Should have 1 cancelled order');
            
            // Order 2: Has invoice with POD_Status__c = 'Uploaded' -> closed  
            // Order 5: Has mixed invoices but one with 'Uploaded' (isClosed = true, breaks loop) -> closed
            System.assertEquals(2, result.get('closed'), 'Should have 2 closed orders');
            
            // Order 3: Has invoices with 'Not Uploaded', null, 'None' POD_Status -> intransit
            System.assertEquals(1, result.get('intransit'), 'Should have 1 intransit order');
            
            // Order 4: No invoices, not rejected -> inprogress
            System.assertEquals(1, result.get('inprogress'), 'Should have 1 inprogress order');

            // Verify total count
            Integer totalCount = result.get('cancelled') + result.get('closed') + result.get('intransit') + result.get('inprogress');
            System.assertEquals(5, totalCount, 'Total count should be 5 orders');
        }
    }

    @IsTest
    static void testOrderMethodEdgeCases() {
        // Test with no orders in date range
        User testUser = [SELECT Id FROM User WHERE Email = 'testuser@example.com' AND IsActive = true LIMIT 1];
        
        System.runAs(testUser) {
            Date startDate = System.today().addDays(10); // Future dates, no orders
            Date endDate = System.today().addDays(15);

            Test.startTest();
            Map<String, Integer> result = orderCountApex.orderMethod(startDate, endDate);
            Test.stopTest();

            System.assertNotEquals(null, result, 'Result should not be null even with no orders');
            
            // All counts should be 0
            System.assertEquals(0, result.get('cancelled'), 'Should have 0 cancelled orders');
            System.assertEquals(0, result.get('closed'), 'Should have 0 closed orders');
            System.assertEquals(0, result.get('intransit'), 'Should have 0 intransit orders');
            System.assertEquals(0, result.get('inprogress'), 'Should have 0 inprogress orders');
        }
    }

    @IsTest
    static void testOrderMethodInvoiceLogic() {
        // Create additional test data to specifically test invoice classification logic
        Account testAccount = new Account(Name = 'Invoice Logic Test Account');
        insert testAccount;

        Contact testContact = new Contact(
            FirstName = 'Invoice',
            LastName = 'Test',
            AccountId = testAccount.Id
        );
        insert testContact;

        Profile p = [SELECT Id FROM Profile WHERE Name = 'Partner Distributor Access' LIMIT 1];
        User invoiceTestUser = new User(
            FirstName = 'Invoice',
            LastName = 'Test',
            Username = 'invoicetest' + DateTime.now().getTime() + '@example.com',
            Email = 'invoicetest@example.com',
            Alias = 'itest',
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = p.Id,
            ContactId = testContact.Id
        );
        insert invoiceTestUser;

        // Create order and invoices as system admin
        System.runAs(new User(Id = UserInfo.getUserId())) {
            Id recordTypeId;
            try {
                if (Schema.SObjectType.Order.getRecordTypeInfosByName().containsKey('Purchase Order')) {
                    recordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByName().get('Purchase Order').getRecordTypeId();
                } else {
                    recordTypeId = null; // fallback if not found
                }
            } catch (Exception e) {
                recordTypeId = null;
            }

            // Create order with multiple invoices to test the break logic
            Order testOrder = new Order(
                AccountId = testAccount.Id,
                EffectiveDate = System.today(),
                Status = 'Draft',
                Type__c = 'Channel Sales',
                Approval_Status__c = 'Approved',
                RecordTypeId = recordTypeId,
                Wattage_Wp_Cell_Module1__c = '540.00',
                Product_Details_Technology_Type__c = 'MONOPERC_MONOFACIAL-M10',
                DCR_Non_DCR1__c = 'DCR',
                Segment1__c = 'CELL_DOMESTIC',
                Domestic_Exports__c = 'Domestic',
                Product_Category__c = 'CELL',
                TotalQuantity__c = '1340',
                Premier_Business_Entity1__c = 'PEL',
                Plant_Store_Name__c = 'PEL - ANNARAM PLANT',
                Delivery_required_by__c = System.today().addDays(7),
                Total_Capacity_in_MWp__c = 0.40
            );
            insert testOrder;

            // Create multiple invoices - first 'Not Uploaded', then 'Uploaded'
            List<Invoice__c> testInvoices = new List<Invoice__c>();
            testInvoices.add(new Invoice__c(
                Order__c = testOrder.Id,
                POD_Status__c = 'Not Uploaded',
                Account__c = testAccount.Id
            ));
            testInvoices.add(new Invoice__c(
                Order__c = testOrder.Id,
                POD_Status__c = 'Uploaded', // This should trigger break
                Account__c = testAccount.Id
            ));
            testInvoices.add(new Invoice__c(
                Order__c = testOrder.Id,
                POD_Status__c = 'Not Uploaded', // This should not be processed due to break
                Account__c = testAccount.Id
            ));
            insert testInvoices;
        }

        // Test as the partner user
        System.runAs(invoiceTestUser) {
            Test.startTest();
            Map<String, Integer> result = orderCountApex.orderMethod(System.today(), System.today());
            Test.stopTest();

            // The order should be classified as 'closed' because of the 'Uploaded' invoice
            System.assertEquals(1, result.get('closed'), 'Order with Uploaded invoice should be closed');
        }
    }
}