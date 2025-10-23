@RestResource(urlMapping='/externalOrders/*')
global without sharing class CreateOrder {
    @HttpGet
    global static List<ExternalOrderWrapper> getAllOrderDetails() {
        List<ExternalOrderWrapper> orderWrappers = new List<ExternalOrderWrapper>();
        
        Id salesOrderRecordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('Sales_Order').getRecordTypeId();
        System.debug('salesOrderRecordTypeId'+salesOrderRecordTypeId);

        // Fetch Orders
        List<Order> orders = [
            SELECT Id, Name,OrderNumber, Status, CreatedDate, EffectiveDate, AccountId, Account.Name,
                   Distribution_Channel__c, Division__c, Incolocation__c, Incoterms__c,
                   Payment_Terms__c, Plant__c, Sales_Org__c, Segment1__c,
                   Bill_To_Customer_Code__c, Ship_To_Customer_Code__c, Shipping_Point__c,
                   PoNumber,Product_type__c,Cust_Ref_Date__c,Product_Category__c
            FROM Order
           // WHERE OrderNumber IN ('00000261', '00000260')
           WHERE SAP_Order_Id__c = null
           AND RecordTypeId =: salesOrderRecordTypeId
        ];

        Set<Id> orderIds = new Set<Id>();
        for (Order o : orders) {
            orderIds.add(o.Id);
        }

        // Fetch related Order Items
        Map<Id, List<OrderItem>> orderItemsMap = new Map<Id, List<OrderItem>>();
        for (OrderItem item : [
            SELECT Id, Quantity, UnitPrice, Product2.Name,Product2.Product_Details_Technology_Type__c, Description, OrderId,
                   CurrencyIsoCode, Product2.Family,Material_Number__c,Segment1__c,DCR_Non_DCR__c,Product2.Material_Number__c
            FROM OrderItem
            WHERE OrderId IN :orderIds
        ]) {
            if (!orderItemsMap.containsKey(item.OrderId)) {
                orderItemsMap.put(item.OrderId, new List<OrderItem>());
            }
            orderItemsMap.get(item.OrderId).add(item);
        }

        // Build Wrappers
        for (Order ord : orders) {
            ExternalOrderWrapper wrapper = new ExternalOrderWrapper();

            wrapper.Order_Type = 'ZDOR';
            wrapper.Sales_org = '2000';
            wrapper.Distribution_Channel = '10';
            wrapper.Division = '10'; // Default
            wrapper.Sold_To_Party = ord.Bill_To_Customer_Code__c;
            wrapper.Ship_to_Party = ord.Ship_To_Customer_Code__c;
            wrapper.PO_Number = ord.PoNumber;
            wrapper.Cust_Ref_date = Date.valueOf(ord.Cust_Ref_Date__c);
            wrapper.Pyt_terms = ord.Payment_Terms__c;
            wrapper.Incoterms = ord.Incoterms__c;
            wrapper.Inco_Location = ord.Incolocation__c;
            wrapper.OrderNumber = ord.OrderNumber;
            wrapper.productType = ord.Product_Category__c;
           // wrapper.DCR_NON_DCR = ord.DCR_Non_DCR__c;
            wrapper.Line_items = new List<LineItemWrapper>();
            
            List<OrderItem> items = orderItemsMap.get(ord.Id);
        if (items != null) {
            for (OrderItem item : items) {
                wrapper.Line_items.add(new LineItemWrapper(
                 item.Product2 != null ? item.Product2.Product_Details_Technology_Type__c : '',
                 item.Segment1__c,
                 item.Quantity,
                 ord.Plant__c,
                 ord.Shipping_Point__c,
                 item.UnitPrice,
                 item.CurrencyIsoCode,
                 item.Product2.Material_Number__c,
                 item.DCR_Non_DCR__c
                 
          ));
       }
    }
            orderWrappers.add(wrapper);
        }

        return orderWrappers;
    }
    
    @HttpPost
global static Map<String, String> updateSAPOrderId() {
    RestRequest req = RestContext.request;
    String requestBody = req.requestBody.toString();

    Map<String, String> response = new Map<String, String>();

    try {
        // Parse incoming JSON from SAP/Middleware
        Map<String, Object> payload = (Map<String, Object>) JSON.deserializeUntyped(requestBody);

        String orderNumber     = (String) payload.get('OrderNumber');
        String sapOrderId      = (String) payload.get('SAPOrderId');
        String sapResponseMsg  = (String) payload.get('Message'); // From SAP

        if (String.isNotBlank(orderNumber) && String.isNotBlank(sapOrderId)) {
            List<Order> matchingOrders = [
                SELECT Id, SAP_Order_Id__c,Response_Message__c
                FROM Order
                WHERE OrderNumber = :orderNumber
                LIMIT 1
            ];

            if (!matchingOrders.isEmpty()) {
                Order ord = matchingOrders[0];
                ord.SAP_Order_Id__c = sapOrderId;
                ord.Response_Message__c = sapResponseMsg;

                update ord;

                response.put('status', 'success');
                response.put('message', 'Order updated. SAP says: ' + sapResponseMsg);
            } else {
                response.put('status', 'error');
                response.put('message', 'OrderNumber not found: ' + orderNumber);
            }
        } else {
            response.put('status', 'error');
            response.put('message', 'Missing OrderNumber or SAPOrderId.');
        }
    } catch (Exception e) {
        response.put('status', 'error');
        response.put('message', 'Exception: ' + e.getMessage());
    }

    return response;
}

    global class ExternalOrderWrapper {
        public String Order_Type;
        public String Sales_org;
        public String Distribution_Channel;
        public String Division;
        public String Sold_To_Party;
        public String Ship_to_Party;
        public String PO_Number;
        public Date Cust_Ref_date;
        public String Pyt_terms;
        public String Incoterms;
        public String Inco_Location;
        public String OrderNumber;
       
        
        public String productType;
        public List<LineItemWrapper> Line_items;
    }

    global class LineItemWrapper {
        public String Material;
        public String Product;
        public Integer Qty;
        public String Plant;
        public String Shipping_point;
        public Decimal Price;
        public String Segment;
        public String currencyVal;
        public String DCR_NON_DCR;

        global LineItemWrapper(
             String productName,String Segment, Decimal qty, String plant, String shipPoint,
            Decimal price,String currencyVal,String Material,String DCR_NON_DCR
        ) {
           // this.Material_Number__c = material;
            this.Product = productName;
            this.Qty = (Integer)qty;
            this.Plant = plant;
            this.Shipping_point = shipPoint;
            this.Price = price;
            this.currencyVal = currencyVal; 
            this.Segment = Segment;
            this.Material = Material;
            this.DCR_NON_DCR = DCR_NON_DCR;
        }
    }
}