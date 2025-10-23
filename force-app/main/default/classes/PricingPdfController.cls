public with sharing class PricingPdfController {
    public List<ProductWrapper> products { get; set; }
    public Decimal finalPrice { get; set; }
    public Decimal finalPriceinCent { get; set; }
    public String countrySource { get; set; }
    public List<InboundLog> inboundLogs { get; set; }
    public List<InboundLog> chinaLogs { get; set; }
    public List<InboundLog> malaysiaLogs { get; set; }
    public List<InboundLog> vietnamLogs { get; set; }
    public List<SeaFreightRow> seaFreightData { get; set; }
    public List<InlandTransportRow> inlandTransportData { get; set; }
    public Map<String, String> financialParamsMap { get; set; }
    public List<AopEbitdaRow> aopEbitdaList { get; set; }
    public List<PreEbitdaRow> preEbitdaList { get; set; }
    public List<Map<String, Object>> indiaMakeList { get; set; }
    public List<Map<String, Object>> countryMakeList { get; set; }
    public List<String> countryLabels { get; set; }
    public List<Map<String, Object>> packagingList { get; set; }
    public List<Map<String, Object>> outboundList { get; set; }
    public String opportunityName { get; set; }
    public String opportunityId { get; set; } 
    public String kamName { get; set; }
    public String approverName { get; set; }
    public String currentDateTime { get; set; }
    
    public PricingPdfController() {
        
        String oppId= ApexPages.currentPage().getParameters().get('recordId');
        Opportunity opp=[Select Id,PricingRawJSON__c,PricingAdminJSON__c,PricingInboundJSON__c,
                         PricingSeaFreightJSON__c,PricingInLandTranportJSON__c,PricingFinanceJSON__c,
                         PricingAOPJSON__c,PricingPreEbitdaJSON__c,PricingIndiaProJSON__c,
                         PricingCMVProJSON__c,PricingPackageJSON__c,PricingOutboundJSON__c,
                         Name,Owner.Name,National_Head_Approval__c,MD_Approval__c
                         from Opportunity where Id=:oppId];
        opportunityName = opp.Name;
        opportunityId = opp.Id;
        kamName = opp.Owner.Name;
        currentDateTime = ApexPages.currentPage().getParameters().get('approvedDateTime');
        
            String headApproval = ApexPages.currentPage().getParameters().get('headApproval');
            String mdApproval = ApexPages.currentPage().getParameters().get('mdApproval');
            
            if(headApproval == 'Approved'){
                List<User> u = [SELECT Id,Name from User where UserRole.DeveloperName = 'National_Head_Key_Accounts_Private'];
                if(!u.isEmpty()){
                    approverName = u[0].Name; 
                }else{
                    User currentUser = [SELECT Id, Name FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
                    approverName= currentUser.Name;
                }
                
            }else if(mdApproval == 'Approved'){
                List<User> u = [SELECT Id,Name from User where UserRole.DeveloperName = 'Managing_Director'];
                if(!u.isEmpty()){
                    approverName = u[0].Name;
                }else{
                    User currentUser = [SELECT Id, Name FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
                    approverName= currentUser.Name;
                }
                
            }
            System.debug('rawJson Opp-->'+opp.PricingRawJSON__c);
            String rawJson = opp.PricingRawJSON__c;
            String adminJson = opp.PricingAdminJSON__c;
            String inboundJson = opp.PricingInboundJSON__c;
            System.debug('rawJson-->'+rawJson);
            if (rawJson != null && adminJson != null) {
                rawJson = EncodingUtil.urlDecode(rawJson, 'UTF-8');
                adminJson = EncodingUtil.urlDecode(adminJson, 'UTF-8');
                
                ProductWrapper singleProduct = (ProductWrapper) JSON.deserialize(rawJson, ProductWrapper.class);
                products = new List<ProductWrapper>{ singleProduct };
                    
                    List<CostRow> adminCosts = (List<CostRow>) JSON.deserialize(adminJson, List<CostRow>.class);
                singleProduct.costBreakdown = adminCosts;
                
                
                inboundLogs = new List<InboundLog>();
                chinaLogs = new List<InboundLog>();
                malaysiaLogs = new List<InboundLog>();
                vietnamLogs = new List<InboundLog>();
                
                if (opp.PricingInboundJSON__c != null) {
                    inboundJson = EncodingUtil.urlDecode(inboundJson, 'UTF-8');
                    
                    List<Object> rawInboundList = (List<Object>) JSON.deserializeUntyped(inboundJson);
                    
                    for (Object obj : rawInboundList) {
                        Map<String, Object> row = (Map<String, Object>) obj;
                        
                        InboundLog log = new InboundLog();
                        log.Name = (String) row.get('Name');
                        row.remove('Name'); 
                        log.extraFields = row;
                        
                        inboundLogs.add(log);
                    }
                    for (InboundLog log : inboundLogs) {
                        Map<String, Object> e = log.extraFields;
                        
                        if (   (e.containsKey('China_BCD__c') && (e.get('China_BCD__c') != null && (Decimal)e.get('China_BCD__c') != 0))
                            || (e.containsKey('China_ADD__c') && (Decimal)e.get('China_ADD__c') != 0)
                            || (e.containsKey('China_CVD__c') && (Decimal)e.get('China_CVD__c') != 0)
                            || (e.containsKey('China_SWS__c') && (Decimal)e.get('China_SWS__c') != 0)
                            || (e.containsKey('China_AIDC__c') && (Decimal)e.get('China_AIDC__c') != 0)) {
                                chinaLogs.add(log);
                            }
                        
                        if (   (e.containsKey('Malaysia_BCD__c'))
                            || (e.containsKey('Malaysia_ADD__c'))
                            || (e.containsKey('Malaysia_CVD__c'))
                            || (e.containsKey('Malaysia_AIDC__c') )) {
                                malaysiaLogs.add(log);
                            }
                        
                        if (   (e.containsKey('Vietnam_Bcd__c'))
                            || (e.containsKey('Vietnam_ADD__c'))
                            || (e.containsKey('Vietnam_CVD__c'))
                            || (e.containsKey('Vietnam_AIDC__c'))) {
                                vietnamLogs.add(log);
                            }
                        
                    }
                }
                
                if (opp.PricingSeaFreightJSON__c != null) {
                    String freightJson = EncodingUtil.urlDecode(opp.PricingSeaFreightJSON__c, 'UTF-8');
                    List<Object> rawList = (List<Object>) JSON.deserializeUntyped(freightJson);
                    
                    seaFreightData = new List<SeaFreightRow>();
                    for (Object obj : rawList) {
                        Map<String, Object> row = (Map<String, Object>) obj;
                        
                        SeaFreightRow freight = new SeaFreightRow();
                        freight.containerSize = (String) row.get('containerSize');
                        Map<String, Object> rawFormatted = (Map<String, Object>) row.get('formattedValues');
                        Map<String, String> formattedMap = new Map<String, String>();
                        
                        for (String key : rawFormatted.keySet()) {
                            formattedMap.put(key, String.valueOf(rawFormatted.get(key)));
                        }
                        
                        freight.formattedValues = formattedMap;
                        
                        seaFreightData.add(freight);
                    }
                }
                if (opp.PricingInLandTranportJSON__c != null) {
                    String inlandJson = EncodingUtil.urlDecode(opp.PricingInLandTranportJSON__c, 'UTF-8');
                    List<Object> rawInlandList = (List<Object>) JSON.deserializeUntyped(inlandJson);
                    
                    inlandTransportData = new List<InlandTransportRow>();
                    for (Object obj : rawInlandList) {
                        Map<String, Object> row = (Map<String, Object>) obj;
                        
                        InlandTransportRow inland = new InlandTransportRow();
                        inland.containerSize = (String) row.get('containerSize');
                        Map<String, Object> rawFormatted = (Map<String, Object>) row.get('formattedValues');
                        Map<String, String> formattedMap = new Map<String, String>();
                        
                        for (String key : rawFormatted.keySet()) {
                            formattedMap.put(key, String.valueOf(rawFormatted.get(key)));
                        }
                        
                        inland.formattedValues = formattedMap;
                        
                        inlandTransportData.add(inland);
                    }
                }
                
                financialParamsMap = new Map<String, String>();
                
                if (opp.PricingFinanceJSON__c != null) {
                    String financeJson = EncodingUtil.urlDecode(opp.PricingFinanceJSON__c, 'UTF-8');
                    Map<String, Object> paramMap = (Map<String, Object>) JSON.deserializeUntyped(financeJson);
                    
                    Set<String> skipKeys = new Set<String>{'Id', 'MasterLabel', 'DeveloperName'};
                        
                        for (String key : paramMap.keySet()) {
                            if (!skipKeys.contains(key)) {
                                financialParamsMap.put(key, String.valueOf(paramMap.get(key)));
                            }
                        }
                }
                aopEbitdaList = new List<AopEbitdaRow>();
                
                if (opp.PricingAOPJSON__c != null) {
                    String aopJson = EncodingUtil.urlDecode(opp.PricingAOPJSON__c, 'UTF-8');
                    aopEbitdaList = (List<AopEbitdaRow>) JSON.deserialize(aopJson, List<AopEbitdaRow>.class);
                }
                preEbitdaList = new List<PreEbitdaRow>();
                
                if (opp.PricingPreEbitdaJSON__c != null) {
                    String preJson = EncodingUtil.urlDecode(opp.PricingPreEbitdaJSON__c, 'UTF-8');
                    preEbitdaList = (List<PreEbitdaRow>) JSON.deserialize(preJson, List<PreEbitdaRow>.class);
                }
                
                if (opp.PricingIndiaProJSON__c != null) {
                    String indiaJson = EncodingUtil.urlDecode(opp.PricingIndiaProJSON__c, 'UTF-8');
                    
                    List<Object> tempList = (List<Object>) JSON.deserializeUntyped(indiaJson);
                    indiaMakeList = new List<Map<String, Object>>();
                    
                    for (Object obj : tempList) {
                        indiaMakeList.add((Map<String, Object>) obj);
                    }
                }	
                countryMakeList = new List<Map<String, Object>>();
                countryLabels = new List<String>();
                
                countrySource = ApexPages.currentPage().getParameters().get('countrySource');
                if (countrySource == null) {
                    countrySource = 'China';
                }
                
                String jsonString =opp.PricingCMVProJSON__c;
                List<Object> rawList = (List<Object>) JSON.deserializeUntyped(jsonString);
                
                for (Object obj : rawList) {
                    countryMakeList.add((Map<String, Object>) obj);
                }
                
                if (!countryMakeList.isEmpty()) {
                    Map<String, Object> firstRow = countryMakeList[0];
                    
                    for (String key : firstRow.keySet()) {
                        if (key.startsWith(countrySource)) {
                            countryLabels.add(key);
                        }
                    }
                    countryLabels.sort();
                }
                
                String packagingJson =opp.PricingPackageJSON__c;
                List<Object> rawListpackage = (List<Object>) JSON.deserializeUntyped(packagingJson);
                packagingList = new List<Map<String, Object>>();
                
                for (Object obj : rawListpackage) {
                    packagingList.add((Map<String, Object>) obj);
                }
                
                if(opp.PricingOutboundJSON__c!= null){
                    String outJson =opp.PricingOutboundJSON__c;
                    List<Object> rawListout = (List<Object>) JSON.deserializeUntyped(outJson);
                    outboundList = new List<Map<String, Object>>();
                    for (Object obj : rawListout) {
                        outboundList.add((Map<String, Object>) obj);
                    }
                }
                finalPrice = Decimal.valueOf(ApexPages.currentPage().getParameters().get('finalPrice'));
                finalPriceinCent = Decimal.valueOf(ApexPages.currentPage().getParameters().get('finalPriceinCent'));
                countrySource = ApexPages.currentPage().getParameters().get('countrySource');
            } else {
                products = new List<ProductWrapper>();
                finalPrice = 0;
                finalPriceinCent = 0;
                countrySource = 'China';
            }
        }
        
        
        public class ProductWrapper {
            public String productName { get; set; }
            public Decimal totalInrWp { get; set; }
            public Decimal totalCentWp { get; set; }
            public List<MaterialWrapper> materials { get; set; }
            public List<CostRow> costBreakdown { get; set; }
        }
        
        
        public class MaterialWrapper {
            public String rawMaterialName { get; set; }
            public String uom { get; set; }
            public String requiredQuantityPerUnit { get; set; }
            public String formattedRawCostUSD { get; set; }
            public String formattedRawCostINR { get; set; }
            public String formattedLogistics { get; set; }
            public String formattedInsurance { get; set; }
            public String formattedDuty { get; set; }
            public String formattedDdp { get; set; }
            public String formattedInrWp { get; set; }
            public String formattedCentsDp { get; set; }
        }
        
        public class CostRow {
            public String label { get; set; }
            public String col2 { get; set; }
            public String col3 { get; set; }
        }
        public class InboundLog {
            public String Name { get; set; }
            public Map<String, Object> extraFields { get; set; }
        }
        public class SeaFreightRow {
            public String containerSize { get; set; }
            public Map<String, String> formattedValues { get; set; }
        }
        public class InlandTransportRow {
            public String containerSize { get; set; }
            public Map<String, String> formattedValues { get; set; }
        }
        public class FinancialParam {
            public String label { get; set; }
            public String value { get; set; }
        }
        public class AopEbitdaRow {
            public String masterLabel { get; set; }
            public Decimal dcr { get; set; }
            public Decimal ndcr { get; set; }
        }  
        public class PreEbitdaRow {
            public String masterLabel { get; set; }
            public Decimal dcr { get; set; }
            public Decimal ndcr { get; set; }
        }  
        
        
    }