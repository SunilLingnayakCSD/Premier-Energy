public without sharing class HomeOrderControllers {


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
               ( SELECT Id, Address__City__s, Address__Street__s, Address__PostalCode__s, Address__StateCode__s, Address__CountryCode__s, Address__Latitude__s, Address__Longitude__s, Address__GeocodeAccuracy__s, Customer_Code__c, Address_Type__c  FROM Adresses__r)
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
        
  @AuraEnabled(cacheable=true)
public static List<AccountStatsWrapper> userCounts(Id recordId) {
    System.debug('Logged-in User Id: ' + recordId);

    List<User> userList = [SELECT Id, Email FROM User WHERE Id = :recordId];
    if (userList.isEmpty()) {
        System.debug('No User found for the provided Id.');
        return new List<AccountStatsWrapper>();
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
    System.debug('Associated Account IDs: ' + accountIds);
    
    Id currentUserId = UserInfo.getUserId();
    System.debug('currentUserId'+currentUserId);
    Id leadRecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Key Account Private').getRecordTypeId();
    System.debug('leadRecordTypeId'+leadRecordTypeId);


    // Query all leads assigned to these accounts
    List<Lead> leads = [
        SELECT Id, Assigned_Distributor__c, Status
        FROM Lead
        WHERE Assigned_Distributor__c =: currentUserId
        AND Status = 'New' 
        AND RecordTypeId =: leadRecordTypeId
    ];
    System.debug('Non-converted Leads: ' + leads);

    // Map to store non-converted lead counts per account
    Map<Id, Integer> nonConvertedLeadCounts = new Map<Id, Integer>();
    
    // Initialize counts for all relevant accounts
    for (Id accId : accountIds) {
        nonConvertedLeadCounts.put(accId,0);
    }
    
    // Count non-converted leads
    for (Lead l : leads) {
        Id accountId = l.Assigned_Distributor__c;
        nonConvertedLeadCounts.put(accountId, nonConvertedLeadCounts.get(accountId) + 1);
    }

    // Get account information
    List<Account> accounts = [
        SELECT Id, Name, Phone, ShippingCity, ShippingStreet, ShippingCountry,
               ShippingState, ShippingPostalCode, BillingStreet, BillingCity,
               BillingState, BillingPostalCode, BillingCountry,Customer_GST_Number__c,
               (SELECT Id, Name, FirstName, LastName, Email, Phone FROM Contacts),
               (SELECT Id, Status FROM Cases WHERE Status != 'Hold')
        FROM Account
        WHERE Id IN :accountIds
    ];

    List<AccountStatsWrapper> accountStatsWrappers = new List<AccountStatsWrapper>();

    for (Account account : accounts) {
        AccountStatsWrapper wrapper = new AccountStatsWrapper(account);
        
        // Add the non-converted lead count
        wrapper.nonConvertedLeads = nonConvertedLeadCounts.get(account.Id) != null 
            ? nonConvertedLeadCounts.get(account.Id) 
            : 0;
		System.debug('wrapper.nonConvertedLeads'+wrapper.nonConvertedLeads);
        accountStatsWrappers.add(wrapper);
    }
    
    System.debug(JSON.serializePretty(accountStatsWrappers));
    return accountStatsWrappers;
} 
    
    
    @AuraEnabled(cacheable=true)
    public static Integer getNewLeadsCountByUser(Id recordId) {
        // Get the RecordTypeId of 'New' Leads
        Id leadRecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Key Account Private').getRecordTypeId();

        // Query leads assigned to the logged-in user with 'New' status and a specific RecordType
        Integer newLeadsCount = [
            SELECT COUNT()
            FROM Lead
            WHERE Assigned_Distributor__c = :recordId
            AND Status = 'New'  // Only consider non-converted leads
            AND RecordTypeId = :leadRecordTypeId
        ];

        return newLeadsCount;
    }
    
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
        SELECT Product2Id, Product2.Name,Product2.Wp__c, IsActive, UnitPrice, LastModifiedDate
        FROM PricebookEntry
        WHERE IsActive = true
        AND Product2.RecordTypeId = :channelSalesRT.Id
       // AND LastModifiedDate >= :firstDay
       // AND LastModifiedDate <= :lastDay
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
            SELECT Id,Term1__c,Term2__c,Term3__c,Term4__c 
            FROM Order_Terms_and_Conditions__mdt
        ];
    }
  
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
@AuraEnabled(cacheable=true)
public static Price_Condition__c getpricingiCondition(String recordId){
    try {
        Price_Condition__c priceCondition=[Select Id,Name,Discount_Type__c,Material_No__c,Pallet_Factor__c,Product__c,Valid_From__c,Valid_To__c,Pallet_Max__c,Pallet_Min__c,WpFormula__c,Discount_Value__c FROM Price_Condition__c WHERE Product__c=:recordId limit 1];
        System.debug('results--->'+priceCondition);
        if(priceCondition !=null){
        return priceCondition;
        }
        return null;
    } catch (Exception e) {
        throw new AuraHandledException(e.getMessage());
    }
}
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

        Pricebook2 standardPricebook = [
        SELECT Id
        FROM Pricebook2
        WHERE IsStandard = TRUE
        LIMIT 1
      ];
    String selectedPricebookId = standardPricebook.Id;
        Order ord = new Order();
        ord.AccountId = orderData.account;
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
        ord.Plant__c = 'PEPPL-KOTHUR DEPOT-2361';
        ord.Shipping_Point__c = '2361';
        ord.Segment__c = 'Module/Domestic/Residential';
        
        ord.Bill_To_Customer_Code__c=orderData.billingAddress.customerCode;
        ord.Ship_To_Customer_Code__c=orderData.shippingAddress.customerCode;
        
        ord.BillingCity = orderData.billingAddress.city;
        ord.BillingPostalCode = orderData.billingAddress.postalCode;
        ord.BillingStateCode = orderData.billingAddress.stateCode;
        ord.BillingCountryCode = orderData.billingAddress.countryCode;

        
        ord.ShippingCity = orderData.shippingAddress.city;
        ord.ShippingPostalCode = orderData.shippingAddress.postalCode;
        ord.ShippingStateCode = orderData.shippingAddress.stateCode;
        ord.ShippingCountryCode = orderData.shippingAddress.countryCode;

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
        if (orderData.fileName != null && orderData.fileContent != null) {
            Attachment att = new Attachment();
            att.ParentId = ord.Id;
            att.Name = orderData.fileName;
            att.Body = EncodingUtil.base64Decode(orderData.fileContent);
            att.ContentType = 'application/octet-stream';
            insert att;
        }

        return ord.Id;

    } catch (Exception e) {
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