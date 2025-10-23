public without sharing class HomeOrderControllers {
    
    // Logged inUser Address Details
    @AuraEnabled(cacheable=true)
    public static List<Account> getAccountAddressDetails(String recordId){
        try {
            List<User> userList = [SELECT Id, Email FROM User WHERE Id = :recordId];
            if (userList.isEmpty()) {
                System.debug('No User found for the provided Id.');
                return new List<Account>();
            }
            User userEmail = userList[0];
            System.debug('User email: ' + userEmail.Email);
            
            List<Contact> contacts = [
                SELECT AccountId, Email
                FROM Contact
                WHERE Email = :userEmail.Email
            ];
            System.debug('Contacts: ' + contacts);
            
            List<Id> accountIds = new List<Id>();
            for (Contact contact : contacts) {
                if (contact.AccountId != null) {
                    accountIds.add(contact.AccountId);
                }
            }
            List<Account> accounts = [
                SELECT Id, Name,
                ( SELECT Id,Name,State__c,Street__c, Country__c, Pincode__c,City__c,Customer_Code__c,Ship_To__c,Address_Type__c FROM Adresses__r)
                FROM Account
                WHERE Id IN :accountIds
            ];
            if(accounts.size()>0){
                return accounts;
            }else{
                return new List<Account>();
            }
            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    //Logged in User Account
    
    @AuraEnabled(cacheable=true)
    public static Account getAccountForUser(Id recordId) {
        System.debug('Logged-in User Id: ' + recordId);
        
        // Get the User's email
        User user = [SELECT Id, Email FROM User WHERE Id = :recordId LIMIT 1];
        
        // Find Contact with matching email and related Account
        List<Contact> contacts = [
            SELECT AccountId
            FROM Contact
            WHERE Email = :user.Email
            AND AccountId != null
            LIMIT 1
        ];
        
        if (contacts.isEmpty()) {
            System.debug('No associated Contact/Account found.');
            return null;
        }
        
        Id accountId = contacts[0].AccountId;
        
        // Return Account fields you need
        Account acc = [
            SELECT Id, Name, Customer_GST_Number__c
            FROM Account
            WHERE Id = :accountId
            LIMIT 1
        ];
        
        return acc;
    }
    //Lead Count
    @AuraEnabled(cacheable=true)
    public static Integer getNewLeadsCountByUser(Id recordId) {
        System.debug('recordId'+recordId);
        Id currentUserId = UserInfo.getUserId();
        System.debug('currentUserId'+currentUserId);
        // Get the RecordTypeId of 'New' Leads
        Id leadRecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Channel Sales').getRecordTypeId();
        
        // Query leads assigned to the logged-in user with 'New' status and a specific RecordType
        Integer newLeadsCount = [
            SELECT COUNT()
            FROM Lead
            WHERE Distributor__c = :currentUserId
            AND Status  = 'New'  // Only consider non-converted leads
            AND RecordTypeId = :leadRecordTypeId
        ];
        
        return newLeadsCount;
    }
    //OrderCount
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> countAndFetchOrdersByUser(Id userId) {
        Map<String, Object> result = new Map<String, Object>();
        
        Integer closedCount = 0;
        Integer inTransitCount = 0;
        
        List<Map<String, String>> closedOrdersList = new List<Map<String, String>>();
        List<Map<String, String>> inTransitOrdersList = new List<Map<String, String>>();
        
        // Get orders owned by user, and their related invoices
        List<Order> orders = [
            SELECT Id, Name,OrderNumber, EffectiveDate,
            (SELECT Id, POD_Status__c FROM Invoices__r)
            FROM Order
            WHERE OwnerId = :userId
            ORDER BY EffectiveDate DESC
        ];
        System.debug('orders'+orders);
        for (Order ord : orders) {
            Boolean isClosed = false;
            Boolean isInTransit = false;
            
            for (Invoice__c inv : ord.Invoices__r) {
                if (inv.POD_Status__c == 'Uploaded') {
                    isClosed = true;
                } else if (inv.POD_Status__c == 'Not Uploaded' || String.isBlank(inv.POD_Status__c)) {
                    isInTransit = true;
                }
            }
            
            if (isClosed) {
                closedCount++;
                if (closedOrdersList.size() < 10) {
                    closedOrdersList.add(new Map<String, String>{
                        'Name' => ord.Name,
                            'orderNumber' => ord.OrderNumber,
                            'Date' => String.valueOf(ord.EffectiveDate),
                            'Id' => ord.Id
                            });
                }
            } else if (isInTransit) {
                inTransitCount++;
                if (inTransitOrdersList.size() < 10) {
                    inTransitOrdersList.add(new Map<String, String>{
                        'Name' => ord.Name,
                            'orderNumber' => ord.OrderNumber,
                            'Date' => String.valueOf(ord.EffectiveDate),
                            'Id' => ord.Id
                            });
                }
            }
        }
        
        result.put('Closed', closedCount);
        result.put('InTransit', inTransitCount);
        result.put('ClosedOrders', closedOrdersList);
        result.put('InTransitOrders', inTransitOrdersList);
        
        return result;
    }
    
    @AuraEnabled(cacheable=true)
    public static List<PricebookEntry> getAllProducts(){
        
        Date today = Date.today();
        Date firstDay = Date.newInstance(today.year(), today.month(), 1);
        System.debug('firstDay'+firstDay);
        Date lastDay = firstDay.addMonths(1).addDays(-1);
        System.debug('lastDay'+lastDay);
        
        // Get RecordType for Channel Sales
        RecordType channelSalesRT = [
            SELECT Id FROM RecordType
            WHERE SObjectType = 'Product2'
            AND DeveloperName = 'Channel_Sales'
            LIMIT 1
        ];
        
        
        // Query filtered PricebookEntries
        List<PricebookEntry> entries = [
            SELECT Product2Id, Product2.Name,Product2.Wp__c,Product2.Family,Product2.Is_Default__c,Product2.Pallet_Factor__c, IsActive, UnitPrice, LastModifiedDate
            FROM PricebookEntry
            WHERE IsActive = true
            AND Product2.Is_Default__c = true 
            AND Product2.RecordTypeId = :channelSalesRT.Id
            
        ];
        System.debug('entries'+entries);
        return entries;
    } 
    
    @AuraEnabled(cacheable=true)
    public static List<PricebookEntry> getFilteredProducts(Integer year, Integer month) {
        Date startDate = Date.newInstance(year, month, 1);
        Date endDate = startDate.addMonths(1);
        
        return [
            SELECT Product2.Name, IsActive, UnitPrice, CreatedDate
            FROM PricebookEntry
            WHERE IsActive = true
            AND CreatedDate >= :startDate
            AND CreatedDate < :endDate
        ];
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Order_Terms_and_Conditions__mdt> getMetaData(){
        return [
            SELECT Id,Term1__c,Term2__c,Term3__c,Term4__c,Term5__c
            FROM Order_Terms_and_Conditions__mdt
        ];
    }
    
    // pricing Schemes
    @AuraEnabled(cacheable=true)
    public static List<PricingSchemeWrapper> checkPricingSchemes(String product1Id,String orderDate) {
        System.debug('************'+product1Id+'&&&&&&&&&&'+'^^^^^^'+orderDate);
        
        List<PricingSchemeWrapper> results = new List<PricingSchemeWrapper>();
        Date orderDateFormatted = Date.valueOf(orderDate);
        
        List<Pricing_Scheme__c> schemes = [
            SELECT Id, Name, Product_1__c, Product_2__c,Product_2__r.Name, Condition_Type__c, 
            Condition_Value__c, Valid_From__c, Valid_To__c
            FROM Pricing_Scheme__c
            WHERE (Product_1__c = :product1Id )
            //AND Product_2__c IN :product2Set)
            AND Valid_From__c <= :orderDateFormatted
            AND Valid_To__c >= :orderDateFormatted
            
        ];
        System.debug('***********'+schemes);
        
        // Convert to wrapper for easier processing in LWC
        for (Pricing_Scheme__c scheme : schemes) {
            results.add(new PricingSchemeWrapper(scheme));
        }
        System.debug('*********'+results);
        return results;
    } 
    
    public class PricingSchemeWrapper {
        @AuraEnabled public String conditionType;
        @AuraEnabled public Decimal conditionValue;
        @AuraEnabled public Id product1Id;
        @AuraEnabled public Id product2Id;
        @AuraEnabled public String proName;
        
        public PricingSchemeWrapper(Pricing_Scheme__c scheme) {
            this.conditionType = scheme.Condition_Type__c;
            this.conditionValue = scheme.Condition_Value__c;
            this.product1Id = scheme.Product_1__c;
            this.product2Id = scheme.Product_2__c;
            this.proName=scheme.Product_2__r.Name;
        }
    }
    
    /**
 * Fetches all applicable pricing conditions for a product based on quantity, pallets, and distributor
 * @param recordId - Product2 ID to find pricing conditions for
 * @param pallets - Total pallets in the order (used for pallet-based pricing tiers)
 * @param quantity - Product quantity or pallets (depending on product unit type)
 * @return List of Price_Condition__c records matching the criteria, ordered by priority
 */
@AuraEnabled(cacheable=true)
public static List<Price_Condition__c> getAllPricingConditions(String recordId, Decimal pallets, Decimal quantity) {
    
    // Get current user's distributor account
    Id currentUserId = UserInfo.getUserId();
    Date today = Date.today();
    
   // System.debug(LoggingLevel.INFO, '--- Entering getAllPricingConditions ---');
   // System.debug(LoggingLevel.INFO, 'Inputs → recordId: ' + recordId + ', pallets: ' + pallets + ', quantity: ' + quantity);
   // System.debug(LoggingLevel.INFO, 'Current User Id: ' + currentUserId + ', Today: ' + today);
    
    User u = [SELECT Contact.AccountId FROM User WHERE Id = :currentUserId LIMIT 1];
    Id distributorId =  u.Contact.AccountId;
   // System.debug(LoggingLevel.INFO, 'Resolved Distributor Account Id: ' + distributorId);
    
    try {
        // Build query to find all matching pricing conditions
        String baseQuery = 'SELECT Id, Name, Discount_Type__c, Material_No__c, ' +
            'Pallet_Factor_Formula__c, Product__c, Valid_From__c, Valid_To__c, ' +
            'Pallet_Max__c, Pallet_Min__c, WpFormula__c, Discount_Value__c, ' +
            'Product_Quantity_From__c, Product_Quantity_To__c, ' +
            'Total_Order_Pallet_From__c, Total_Order_Pallet_To__c, ' +
            'Product_Unit__c, Distributor__c ' +
            'FROM Price_Condition__c ' +
            'WHERE Product__c = :recordId ' +
            'AND Valid_From__c <= :today ' +
            'AND Valid_To__c >= :today ' +
            'AND Total_Order_Pallet_From__c <= :pallets ' +
            'AND Total_Order_Pallet_To__c >= :pallets ' +
            'AND Distributor__c = :distributorId ' +
            'ORDER BY ' +
                'Product_Quantity_From__c NULLS LAST, ' +  // Quantity-specific conditions first
                'Product_Quantity_To__c NULLS LAST, ' +
                'Discount_Value__c DESC, ' +              // Higher discounts first
                'Distributor__c DESC NULLS LAST';
        
       // System.debug(LoggingLevel.INFO, 'Dynamic SOQL Query: ' + baseQuery);
        
        List<Price_Condition__c> conditions = Database.query(baseQuery);
        //System.debug(LoggingLevel.INFO, 'Query returned ' + conditions.size() + ' records');
        
        // Filter conditions based on quantity match
        List<Price_Condition__c> applicableConditions = new List<Price_Condition__c>();
        
        for (Price_Condition__c cond : conditions) {
            boolean quantityMatches = false;
            
            // Check if quantity condition matches
            if (cond.Product_Quantity_From__c == null && cond.Product_Quantity_To__c == null) {
                // No quantity restriction - applies to pallet-only conditions
                quantityMatches = true;
               // System.debug(LoggingLevel.INFO, 'Condition ' + cond.Name + ' - No quantity restriction (pallet-only)');
            } else if (quantity != null && 
                       cond.Product_Quantity_From__c <= quantity && 
                       cond.Product_Quantity_To__c >= quantity) {
                // Quantity-specific condition that matches
                quantityMatches = true;
               // System.debug(LoggingLevel.INFO, 'Condition ' + cond.Name + ' - Quantity matches: ' + quantity);
            }
            
            if (quantityMatches) {
                applicableConditions.add(cond);
               // System.debug(LoggingLevel.INFO, 'Added applicable condition → Id: ' + cond.Id + ', Name: ' + cond.Name);
            }
        }
        
       // System.debug(LoggingLevel.INFO, 'Final applicable conditions count: ' + applicableConditions.size());
        return applicableConditions;
        
    } catch (Exception e) {
        System.debug(LoggingLevel.ERROR, '❌ Error in getAllPricingConditions: ' + e.getMessage() + ' | StackTrace: ' + e.getStackTraceString());
        throw new AuraHandledException('Error fetching pricing: ' + e.getMessage());
    }
}

/**
 * Legacy method - kept for backward compatibility
 * Now calls getAllPricingConditions and returns first result
 */
@AuraEnabled(cacheable=true)
public static Price_Condition__c getpricingCondition(String recordId, Decimal pallets, Decimal quantity) {
    List<Price_Condition__c> conditions = getAllPricingConditions(recordId, pallets, quantity);
    return conditions.isEmpty() ? null : conditions[0];
}

    // invoice count  
    @AuraEnabled(cacheable=true)
    public static Map<String, Integer> getInvoiceCounts() {
        Map<String, Integer> result = new Map<String, Integer>();
        
        // Intransit orders
        Integer intransitCount = [
            SELECT COUNT()
            FROM Invoice__c
            WHERE POD_Status__c != 'uploaded'
        ];
        result.put('intransit', intransitCount);
        
        // Open orders
        Integer openCount = [
            SELECT COUNT()
            FROM Invoice__c
            WHERE POD_Status__c = 'uploaded'
        ];
        result.put('open', openCount);
        
        return result;
    }
    @AuraEnabled(cacheable=true)
    public static List<Invoice__c> getIntransitInvoices() {
        id curentUserId = UserInfo.getUserId();
        return [
            SELECT Id, Name, Invoice_Date__c, POD_Status__c
            FROM Invoice__c
            WHERE POD_Status__c != 'uploaded'
        ];
    }
    @AuraEnabled(cacheable=true)
    public static List<Invoice__c> getOpenOrders() {
        return [
            SELECT Id, Name, Invoice_Date__c, POD_Status__c 
            FROM Invoice__c
            WHERE POD_Status__c = 'uploaded'
        ];
    }
    @AuraEnabled(cacheable=true)
    public static List<Product2> getRelatedProducts(String recordId){
        try {
            List<Product2> products=[Select Id,Name,(Select Id,Name From Products__r where Main_Product__c=:recordId) FROM Product2 where Id=:recordId limit 1 ];
            System.debug('results--->'+products);
            return products;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    @AuraEnabled
    public static String createOrderFromJSON(String orderJson) {
        try {
            OrderWrapper orderData = (OrderWrapper) JSON.deserialize(orderJson, OrderWrapper.class);
            
            User currentUser = [
                SELECT Id, Region1__c
                FROM User
                WHERE Id = :UserInfo.getUserId()
                LIMIT 1
            ];
            
            Pricebook2 standardPricebook = [
                SELECT Id
                FROM Pricebook2
                WHERE IsStandard = TRUE
                LIMIT 1
            ];
            // Account acc = [SELECT Name FROM Account WHERE Id = :orderData.accountId LIMIT 1];
            // system.debug('acc'+acc);
            // 
            //  Get the Account
            List<Account> accList = [
                SELECT Id, Name
                FROM Account
                WHERE Id = :orderData.account
                LIMIT 1
            ];
            
            if (accList.isEmpty()) {
                throw new AuraHandledException('No Account found for Id: ' + orderData.account);
            }
            
            Account acc = accList[0];
            String selectedPricebookId = standardPricebook.Id;
            Order ord = new Order();
            //ord.AccountId = orderData.accountId;
            ord.AccountId = acc.Id;
            ord.Name = acc.Name;
            ord.EffectiveDate = Date.today(); 
            ord.Status = 'Draft'; 
            ord.PoNumber = orderData.PoNumber;
            ord.Grand_Total__c=orderData.grandTotal;
            ord.wptotal__c = orderData.Totalwp;
            ord.TotalQuantity__c= orderData.TotalQuantity;
            ord.Total_Capacity_in_MWp__c = orderData.Mwp;
            ord.PoDate = Date.valueOf(orderData.PoDate); 
            ord.Pricebook2Id = selectedPricebookId;
            ord.Type__c='Channel Sales';
            ord.Type = 'ZDOR';
            ord.Sales_Org__c = '2000';
            ord.Distribution_Channel__c = '10';
            ord.Division__c = '10';
            ord.Payment_Terms__c = '0001';
            ord.Incoterms__c = 'CIF';
            ord.Incolocation__c = 'Kothur';
            ord.Plant__c = '2361';
            ord.Shipping_Point__c = '2361';
            // ord.Segment__c = 'Module/Domestic/Residential';
            ord.Region1__c = currentUser.Region1__c;
            
            ord.Bill_To_Customer_Code__c=orderData.billingAddress.customerCode;
            ord.Ship_To_Customer_Code__c=orderData.shippingAddress.customerCode;
            
            ord.BillingCity = orderData.billingAddress.city;
            ord.BillingPostalCode = orderData.billingAddress.postalCode;
            ord.BillingState = orderData.billingAddress.stateCode;
            ord.BillingCountry = orderData.billingAddress.countryCode;
            ord.BillingStreet = orderData.billingAddress.streetCode;
            
            
            ord.ShippingCity = orderData.shippingAddress.city;
            ord.ShippingPostalCode = orderData.shippingAddress.postalCode;
            ord.ShippingState = orderData.shippingAddress.stateCode;
            ord.ShippingCountry = orderData.shippingAddress.countryCode;
            ord.ShippingStreet  = orderData.shippingAddress.streetCode;
            
            
            insert ord;
            
            
            List<OrderItem> orderItems = new List<OrderItem>();
            for (OrderProductWrapper op : orderData.orderProducts) {
                OrderItem item = new OrderItem();
                item.OrderId = ord.Id;
                item.PricebookEntryId = op.selectedProductId;
                item.Quantity = op.quantity;
                item.UnitPrice = op.price;
                orderItems.add(item);
            }
            
            insert orderItems;
            // if (orderData.fileName != null && orderData.fileContent != null) {
            //     Attachment att = new Attachment();
            //     att.ParentId = ord.Id;
            //     att.Name = orderData.fileName;
            //     att.Body = EncodingUtil.base64Decode(orderData.fileContent);
            //     att.ContentType = 'application/octet-stream';
            //     insert att;
            // }
if (orderData.fileName != null && orderData.fileContent != null) {
    try {
        // Step 1: Create ContentVersion (file upload)
        ContentVersion cv = new ContentVersion();
        cv.Title = orderData.fileName;
        cv.PathOnClient = orderData.fileName;
        cv.VersionData = EncodingUtil.base64Decode(orderData.fileContent);
        cv.Origin = 'H';
        insert cv;

        System.debug('ContentVersion inserted with Id: ' + cv.Id);

        // Step 2: Get the ContentDocumentId
        cv = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id LIMIT 1];
        System.debug('Associated ContentDocumentId: ' + cv.ContentDocumentId);

        // Step 3: Create ContentDocumentLink to link file to the parent record
        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.ContentDocumentId = cv.ContentDocumentId;
        cdl.LinkedEntityId = ord.Id; // The record you want to attach to
        cdl.ShareType = 'V'; // Viewer access
        cdl.Visibility = 'AllUsers'; // Adjust as needed
        insert cdl;

        System.debug('File successfully linked to record: ' + ord.Id);
    } catch (Exception e) {
        System.debug('Error uploading file to Files: ' + e.getMessage());
        throw new AuraHandledException('File upload failed: ' + e.getMessage());
    }
}            
            return ord.Id;
            
        } catch (Exception e) {
            System.debug(e.getMessage());
            throw new AuraHandledException('Error creating order: ' + e.getMessage());
        }
    }
    
    
    public class OrderWrapper {
        public String PoNumber;
        public String PoDate;
        public AddressWrapper billingAddress;
        public AddressWrapper shippingAddress;
        public List<OrderProductWrapper> orderProducts;
        public String account;
        public String fileName;
        public String fileContent;
        public Decimal grandTotal;
        public String Totalwp;
        public String TotalQuantity;
        public Decimal Mwp;
        
    }
    
    public class AddressWrapper {
        public String accountId;         // Formerly Account__c
        public String addressId;         // Formerly Id
        public String city;              // Formerly Address__City__s
        public String postalCode;        // Formerly Address__PostalCode__s
        public String stateCode;         // Formerly Address__StateCode__s
        public String countryCode;       // Formerly Address__CountryCode__s
        public String customerCode;      // Formerly Customer_Code__c
        public String addressType;       // Formerly Address_Type__c
        public String streetCode;
    }
    
    public class OrderProductWrapper {
        public Integer rowId;
        public String selectedProductId;
        public Decimal quantity;
        public Decimal price;
        public Decimal total;
        public String product2Id;
    }
    
}