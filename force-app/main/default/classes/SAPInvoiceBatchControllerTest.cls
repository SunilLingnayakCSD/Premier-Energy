@isTest
private class SAPInvoiceBatchControllerTest {

    @isTest
    static void testInvoiceBatch_InsertInvoiceAndLines() {
        // Create test Account, Order, Product
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Order ord = new Order(
            Name = 'Test Order',
            Status = 'Draft',
            EffectiveDate = Date.today(),
            AccountId = acc.Id,
            SAP_Order_Id__c = 'SO1234'
        );
        insert ord;

        Product2 prod = new Product2(
            Name = 'Test Product',
            Material_Number__c = 'MAT001',
            IsActive = true
        );
        insert prod;

        // Prepare Invoice JSON
        String jsonInput = JSON.serialize(new Map<String, Object>{
            'root' => new List<Map<String, Object>>{
                new Map<String, Object>{
                    'SAP_Invoice_Number'     => 'INV001',
                    'SAP_Sales_Order_Number' => 'SO1234',
                    'Document_Type'          => 'Domestic Invoice',
                    'Invoice_Date'           => String.valueOf(Date.today()),
                    'Sales_Doc_No'           => 'SD001',
                    'LineItems' => new List<Map<String, Object>>{
                        new Map<String, Object>{
                            'Material_Number'      => 'MAT001',
                            'Material_Description' => 'Test Material',
                           'Quantity'             => '10',
                            'Quantity_Unit'        => 'EA', 
                            'Amount'               => '500',
                           // 'Amount_Currency'      => 'INR',
                            'Discount'             => '20',
                            'CGST'                 => '5',
                            'SGST'                 => '5',
                            'IGST'                 => '0'
                        }
                    }
                }
            }
        });

        // Parse JSON into wrappers
        List<SAPInvoiceBatchController.InvoiceWrapper> invoices =
            SAPInvoiceBatchController.parseJson(jsonInput);

        // Execute the batch
        Test.startTest();
        Database.executeBatch(new SAPInvoiceBatchController(invoices), 1);
        Test.stopTest();

        // Assertions
        List<Invoice__c> invList = [SELECT Id, Invoice_Number__c, Document_Type__c FROM Invoice__c WHERE Invoice_Number__c = 'INV001'];
        System.assertEquals(1, invList.size(), 'One invoice should be inserted');

        List<Invoice_Line_Item__c> lineList = [SELECT Id, Product__c, Amount__c FROM Invoice_Line_Item__c WHERE Invoice__c = :invList[0].Id];
        System.assertEquals(1, lineList.size(), 'One line item should be inserted');
        System.assertEquals(500, lineList[0].Amount__c, 'Amount should match');
    }

    @isTest
    static void testInvoiceBatch_CancellationOfNonExistingInvoice() {
        // Set up Account, Order, Product2
        Account acc = new Account(Name = 'Cancel Test Account');
        insert acc;

        Order ord = new Order(
            Name = 'Cancel Order',
            Status = 'Draft',
            EffectiveDate = Date.today(),
            AccountId = acc.Id,
            SAP_Order_Id__c = 'SO5678'
        );
        insert ord;

        Product2 prod = new Product2(
            Name = 'Cancel Product',
            Material_Number__c = 'MAT999',
            IsActive = true
        );
        insert prod;

        // Prepare JSON for cancellation of a new invoice
        String cancelJson = JSON.serialize(new Map<String, Object>{
            'root' => new List<Map<String, Object>>{
                new Map<String, Object>{
                    'SAP_Invoice_Number'     => 'INV-CANCEL',
                    'SAP_Sales_Order_Number' => 'SO5678',
                    'Document_Type'          => 'Invoice Cancellation',
                    'Invoice_Date'           => String.valueOf(Date.today()),
                    'Sales_Doc_No'           => 'SD-CAN-1',
                    'LineItems' => new List<Map<String, Object>>{
                        new Map<String, Object>{
                            'Material_Number'      => 'MAT999',
                            'Material_Description' => 'Canceled Item',
                            'Quantity'             => '2',
                            'Quantity_Unit'        => 'EA',
                            'Amount'               => '100',
                          //  'Amount_Currency'      => 'INR',
                            'Discount'             => '10',
                            'CGST'                 => '2',
                            'SGST'                 => '2',
                            'IGST'                 => '0'
                        }
                    }
                }
            }
        });

        List<SAPInvoiceBatchController.InvoiceWrapper> cancelInvoices =
            SAPInvoiceBatchController.parseJson(cancelJson);

        Test.startTest();
        Database.executeBatch(new SAPInvoiceBatchController(cancelInvoices), 1);
        Test.stopTest();

        // Verify invoice created even though it was cancellation (but new)
        List<Invoice__c> cancelInvs = [SELECT Id, Invoice_Number__c, Is_Cancellation__c FROM Invoice__c WHERE Invoice_Number__c = 'INV-CANCEL'];
        System.assertEquals(1, cancelInvs.size());
        System.assert(cancelInvs[0].Is_Cancellation__c, 'Should be marked as cancellation');

        // Line items should still be inserted because invoice didn't exist before
        List<Invoice_Line_Item__c> cancelLines = [SELECT Id FROM Invoice_Line_Item__c WHERE Invoice__c = :cancelInvs[0].Id];
        System.assertEquals(1, cancelLines.size(), 'Line item should be inserted for new cancellation');
    }

    @isTest
    static void testParseJson_InvalidFormat() {
        // Should throw if "root" key is missing
        String invalidJson = JSON.serialize(new Map<String, Object>{ 'badKey' => new List<Object>() });

        Boolean exceptionThrown = false;
        try {
            SAPInvoiceBatchController.parseJson(invalidJson);
        } catch (Exception e) {
            exceptionThrown = true;
            System.assert(e.getMessage().contains('Missing "root" key'));
        }
        System.assert(exceptionThrown, 'Expected exception for missing root');
    }
}