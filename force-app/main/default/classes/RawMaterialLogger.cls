public with sharing class RawMaterialLogger {
public class CostDataWrapper {
    @AuraEnabled public Decimal rfidCostINR;
    @AuraEnabled public Decimal rfidCostCents;
    @AuraEnabled public Decimal moduleOverheadINR;
    @AuraEnabled public Decimal moduleOverheadCents; 
    @AuraEnabled public Decimal moduleFinanceINR;
    @AuraEnabled public Decimal moduleFinanceCents;
    @AuraEnabled public Decimal cellBOMINR;
    @AuraEnabled public Decimal cellBOMCents;
    @AuraEnabled public Decimal cellOverheadINR;
    @AuraEnabled public Decimal cellOverheadCents;
    @AuraEnabled public Decimal cellFinanceINR;
    @AuraEnabled public Decimal cellFinanceCents;
    @AuraEnabled public Decimal warrantyInsurance;
    @AuraEnabled public String thirdpartywarranty;
    @AuraEnabled public Decimal bgrademodulediscount;
    @AuraEnabled public Decimal bgrademoduleyield;
    @AuraEnabled public Decimal abgvalue;
    @AuraEnabled public Decimal abgpbgcost;
    @AuraEnabled public Decimal abgvalidity;
    @AuraEnabled public Decimal projectcapacity;
    @AuraEnabled public Decimal pbgvalue;
    @AuraEnabled public Decimal pbgvalidity;
    @AuraEnabled public Decimal outboundlogisticsINR;
    @AuraEnabled public Integer noTrucksReq;
    @AuraEnabled public Decimal outboundlogisticsCent;
    @AuraEnabled public Decimal freight;
    @AuraEnabled public Decimal exportfreightchargesCent;
    @AuraEnabled public Decimal exportfreightchargesINR;
    @AuraEnabled public Decimal paymentterm;
    @AuraEnabled public Decimal lcinterestcost;
    @AuraEnabled public String lcusanceperiod;
    @AuraEnabled public Decimal ebitda;
    @AuraEnabled public Decimal insurancepremiumcost;
    @AuraEnabled public Decimal rbi;
    @AuraEnabled public Decimal cbitc;
    @AuraEnabled public String paymenttrembalance;
    @AuraEnabled public List<Outbound_Logistic__c> outboundLogforattachment;

        @AuraEnabled public Boolean isFromNH;
@AuraEnabled public List<Object> jsonRows;
}

public class RawMaterialWrapper {
    @AuraEnabled public String opportunityLineItemId;
    @AuraEnabled public String rawMaterialName;
    @AuraEnabled public String uom;
    @AuraEnabled public Decimal netBoQData;
    @AuraEnabled public String pricingType;
    @AuraEnabled public String countrySource;
    @AuraEnabled public Boolean isVariable;
    @AuraEnabled public Boolean isDefaultSkip;
    @AuraEnabled public String defaultVariantGroupId;
    @AuraEnabled public String rawMaterialId;
    @AuraEnabled public Decimal rawCostUSD;
    @AuraEnabled public Decimal rawCostINR;
    @AuraEnabled public Decimal logisticsCalculation;
    @AuraEnabled public Decimal insurancePercentage;
    @AuraEnabled public Decimal actualPriceUsed;
    @AuraEnabled public Decimal totalCostWithMargin;
    @AuraEnabled public Decimal totalCostWithMarginAdded;
    @AuraEnabled public Decimal rawCostINRPerWattage;
    @AuraEnabled public Decimal rawCostUSDPerWattage;
    @AuraEnabled public Map<String, CountryData> countryDataMap = new Map<String, CountryData>();
    @AuraEnabled public String picklistvalue;
    @AuraEnabled public Decimal qty40Ft;
    @AuraEnabled public Decimal cellWattage;
    @AuraEnabled public Decimal qty20Ft;
    @AuraEnabled public Decimal chinaAdd;
    @AuraEnabled public Decimal chinaAidc;
    @AuraEnabled public Decimal chinaBcd;
    @AuraEnabled public Decimal chinaCvd;
    @AuraEnabled public Decimal chinaSws;
    @AuraEnabled public String productName;

        @AuraEnabled public Boolean isFromNH;
@AuraEnabled public Map<String,Object> jsonRows;
}

public class CountryData {
    @AuraEnabled public Decimal rawCostUSD;
    @AuraEnabled public Decimal rawCostINR;
    @AuraEnabled public Decimal logistics;
    @AuraEnabled public Decimal insurance;
    @AuraEnabled public Decimal priceUsed;
    @AuraEnabled public Decimal totalMargin;
    @AuraEnabled public Decimal totalWithMargin;
    @AuraEnabled public Decimal inrPerWatt;
    @AuraEnabled public Decimal usdPerWatt;
}

    @AuraEnabled(cacheable=true)
    public static String getUserProfileName(Id userId) {
        return [SELECT Profile.Name FROM User WHERE Id = :userId].Profile.Name;
    }
    @AuraEnabled(cacheable=true)
    public static Map<String,String> getCountryPricing(Id oppId) {
        Opportunity opp = [Select Id,Country_Source__c,Pricing_Type__c from Opportunity where Id=:oppId];
        Map<String,String> cp = new Map<String,String>();
        cp.put('countrySource',opp.Country_Source__c);
        cp.put('pricingType',opp.Pricing_Type__c);
        return cp;
    }
    @AuraEnabled
    public static void updateCountry(String country,Id oppId) {
        Opportunity opp = [Select Id,Country_Source__c from Opportunity where Id=:oppId];
        opp.Country_Source__c = country;
        update opp;
    }
    @AuraEnabled
    public static void updatePricingType(String type,Id oppId) {
        Opportunity opp = [Select Id,Pricing_Type__c from Opportunity where Id=:oppId];
        opp.Pricing_Type__c = type;
        update opp;
    }
    @AuraEnabled
    public static void updateFinalWP(Id recordId, Decimal finalprice,Decimal finalpricecent, Decimal pbtvalue ,Decimal moduleFinanceINR,Decimal freight) {
        System.debug('update final-->'+recordId+finalprice+pbtvalue+moduleFinanceINR);
        Opportunity opp = [Select Id,Final_Wp_price__c,PBT_Value__c,Ebita_Value__c,New_PBT_Value__c,New_Ebita_Value__c,
                    Priced_Techno_Commercial_Proposal_Submi__c,Generated_Quote_with_Reference__c,PricingUpdatedByKAM__c,
                    Final_Wp_price_cents__c,freight_cost__c from Opportunity where Id =: recordId];
        opp.Final_Wp_price__c = finalprice;
        opp.Final_Wp_price_cents__c = 'USD '+ finalpricecent;
        opp.PBT_Value__c = pbtvalue;
        opp.New_PBT_Value__c = pbtvalue;
        opp.New_Ebita_Value__c = moduleFinanceINR;
        opp.Priced_Techno_Commercial_Proposal_Submi__c = System.TODAY();
        opp.Ebita_Value__c = moduleFinanceINR;
        opp.freight_cost__c = freight;
        opp.PricingUpdatedByKAM__c = true;
        //if(opp.Discounted_Wp_Price__c == null){
            //   opp.Discounted_Wp_Price__c = finalprice;
        //}
        if (opp.Generated_Quote_with_Reference__c == null) {
                opp.Generated_Quote_with_Reference__c = String.valueOf(finalprice) + ' R1';
            } else {
                String currentRevision = opp.Generated_Quote_with_Reference__c;
                Integer revisionNumber = 1;

                if (currentRevision.contains('R')) {
                    String[] parts = currentRevision.split('R');
                    try {
                        revisionNumber = Integer.valueOf(parts[1].trim()) + 1;
                    } catch (Exception e) {
                        revisionNumber = 1;
                    }
                }

                opp.Generated_Quote_with_Reference__c = String.valueOf(finalprice) + ' R' + revisionNumber;
            }

        update opp;
    }

    @AuraEnabled
    public static void updateFinalWPbyNH(Id recordId, Decimal pbtvalue ,Decimal moduleFinanceINR) {
        System.debug('update final-->'+recordId+pbtvalue+moduleFinanceINR);
        Opportunity opp = [Select Id,Final_Wp_price__c,PBT_Value__c,New_PBT_Value__c,NH_Updated_Price__c,
        Ebita_Value__c,Priced_Techno_Commercial_Proposal_Submi__c,New_Ebita_Value__c,
        Generated_Quote_with_Reference__c,Final_Wp_price_cents__c,freight_cost__c from Opportunity where Id =: recordId];
        opp.New_PBT_Value__c = pbtvalue;
        opp.New_Ebita_Value__c = moduleFinanceINR;
        opp.NH_Updated_Price__c = true;
        update opp;
    }

@AuraEnabled
public static void createVariables(String oppId, String oldRM, String newRM,String oliId){
    
    List<Opportunity> opp = [Select Id,Cable_length__c from Opportunity where Id =:oppId];
    List<OpportunityLineItem> oppLineItems = [SELECT Id FROM OpportunityLineItem WHERE OpportunityId = :opp];

    Product_Raw_Material_Tracking__c prmt = new Product_Raw_Material_Tracking__c();
    prmt.Opportunity_Product__c = oliId;
    prmt.Old_Product_Raw_Materials__c = oldRM;
    prmt.New_Product_Raw_Materials__c = newRM;
    Insert prmt;
    System.debug('prmt-->'+prmt);

    Product_Raw_Materials__c pr = [Select Id,Raw_Materials__r.Name from Product_Raw_Materials__c where Id =: newRM];
    if(pr.Raw_Materials__r.Name.contains('1400mm')){
        opp[0].Cable_length__c = '1400';
    }else{
        opp[0].Cable_length__c = '400';
    }
    update opp;

}

@AuraEnabled(cacheable=true)
public static Boolean alreadyUpdatedByKAM(String oppId){
    List<Opportunity> opp = [Select Id,PricingUpdatedByKAM__c from Opportunity where Id=:oppId];
    if(!opp.isEmpty()){
        if(opp[0].PricingUpdatedByKAM__c == true){
            return true;
        }else{
            return false;
        }
    }
    return false;

}
@AuraEnabled(cacheable=true)
public static Boolean grayoutforNH(String oppId){
    List<Opportunity> opp = [Select Id,PricingUpdatedByKAM__c,National_Head_Approval__c from Opportunity where Id=:oppId];
    if(!opp.isEmpty()){
        if(opp[0].National_Head_Approval__c == 'Sent for Approval'){
            return true;
        }else{
            return false;
        }
    }
    return false;

}

    @AuraEnabled(cacheable=true)
public static Boolean lockingprice(String oppId){
    List<Opportunity> opp = [Select Id,PricingUpdatedByKAM__c,National_Head_Approval__c from Opportunity where Id=:oppId];
    if(!opp.isEmpty()){
        if(opp[0].National_Head_Approval__c == 'Approved' || opp[0].National_Head_Approval__c == 'Escalated'){
            return true;
        }else{
            return false;
        }
    }
    return false;

}

@AuraEnabled(cacheable=true)
public static List<Id> checkVariables(String oppId,List<Id> rawMaterialIds,String oliId)
{
    
    List<Opportunity> opp = [Select Id from Opportunity where Id =:oppId];
    List<OpportunityLineItem> oppLineItems = [SELECT Id FROM OpportunityLineItem WHERE OpportunityId = :opp];
    List<Id> newProductRawMaterialsSet = new List<Id>();
    for (Id rawMaterialId : rawMaterialIds) {
    List<Product_Raw_Material_Tracking__c> prmtList = [
        SELECT Id, New_Product_Raw_Materials__c 
        FROM Product_Raw_Material_Tracking__c
        WHERE (New_Product_Raw_Materials__c = :rawMaterialId OR Old_Product_Raw_Materials__c = :rawMaterialId)
        AND Opportunity_Product__c = :oliId
        ORDER BY CreatedDate DESC
        LIMIT 1
    ];
    
    if (!prmtList.isEmpty()) {
        Product_Raw_Material_Tracking__c prmtRecord = prmtList[0];
        if (prmtRecord.New_Product_Raw_Materials__c != null) {
            newProductRawMaterialsSet.add(prmtRecord.New_Product_Raw_Materials__c);
        }
    }
}
return newProductRawMaterialsSet;

}

@AuraEnabled(cacheable=true)
public static Map<Id, CostDataWrapper> getAdminInputs(Id oppId) 
{
Map<Id, CostDataWrapper> resultMap = new Map<Id, CostDataWrapper>();

    Opportunity opp = [SELECT Id, RFID_Readers_Qty__c, Ship_to__r.Pincode__c,Ship_to__r.State__c, Project_capacity_in_MWp_including_Spare__c, DCR_Non_DCR1__c,LC_Usance_Period_in_Days__c,Third_Party_Warranty_Insurance__c,National_Head_Approval__c,
ABG_Value__c,ABG_Validity_Days__c,PBG_Value__c,PBG_Validity_Days__c,Domestic_Exports__c,Payment_Terms__c,Segment1__c,Plant_Store_Name__c ,Wattage_Wp_Cell_Module1__c,Vehicle_Preference_if_any1__c,PalletBasedOnVehicle__c,Payment_Term_Balance__c,Incoterms__c,PricingAdminJSON__c
    FROM Opportunity WHERE Id = :oppId];


// Master Configs
Input_Admin__mdt cm = [
    SELECT Id, Inland_Inr__c, USD_to_INR_CBITC__c, RFIDreadercost__c, Overhead_cost_mdt__c, Finance_Cost__c,
            Cell_BOM_Cost__c, Cell_Finance_Cost__c, Cell_Overhead_Cost__c, ModuleWarrantyInsurance__c, 
            B_Grade_Module_Discount__c, B_Grade_Module_Yield__c, ABGPBGCostPA__c, LCinterestcostPA__c, 
            InsurnacePremiumcost__c
    FROM Input_Admin__mdt WHERE MasterLabel = 'default' LIMIT 1
];

List<OpportunityLineItem> oppLineItems = [
    SELECT Id, Product2.Wp__c, Product2.Pallet_Factor__c, DCR_Non_DCR1__c, Opportunity.Wattage_Wp_Cell_Module1__c
    FROM OpportunityLineItem
    WHERE OpportunityId = :oppId
];
if (oppLineItems.isEmpty()) return resultMap;

    if (opp.National_Head_Approval__c == 'Approved' || opp.National_Head_Approval__c == 'Escalated') {
    List<Object> jsonList = (List<Object>) JSON.deserializeUntyped(opp.PricingAdminJSON__c);


    for (OpportunityLineItem oli : oppLineItems) {
        CostDataWrapper data = new CostDataWrapper();
        data.jsonRows = jsonList;
        data.isFromNH = true; 
        resultMap.put(oli.Id, data);
    }

    return resultMap;
}else{

    List<Plant_with_Pincode__mdt> pc = [Select Id,Plant_Pincode__c,MasterLabel from Plant_with_Pincode__mdt where MasterLabel=:opp.Plant_Store_Name__c];
    List<Outbound_Logistic__c> ol = new List<Outbound_Logistic__c>();
    if(!pc.isEmpty() && opp.Ship_to__r.Pincode__c!= null && opp.Ship_to__r.State__c!=null && pc[0].Plant_Pincode__c!=null){
    ol = [Select Id,Name,Customer_Pincode__c,Plant_Pincode__c,Distance_in_kms__c,State__c,Price_Km__c from Outbound_Logistic__c
        where Customer_Pincode__c=:Integer.valueof(opp.Ship_to__r.Pincode__c) and Plant_Pincode__c=:pc[0].Plant_Pincode__c and State__c=: opp.Ship_to__r.State__c];
    }

List<Segment__mdt> cms = [SELECT Id, MasterLabel, DeveloperName,DCR__c,NDCR__c FROM Segment__mdt WHERE MasterLabel =: opp.Segment1__c LIMIT 1];

List<Input_Inbound_Logistics__mdt> inboundlogic= [Select Id,MasterLabel,Export_Freight_Charges__c,DeveloperName  from Input_Inbound_Logistics__mdt where DeveloperName ='Input_Inbound_Logists_fields'];


for (OpportunityLineItem oli : oppLineItems) {
    CostDataWrapper data = new CostDataWrapper();

    Decimal wattage = oli.Product2.Wp__c ?? 0;
    Decimal inlandInr = cm.Inland_Inr__c;
    Decimal usdToInrRate = cm.USD_to_INR_CBITC__c;

    // RFID Cost per watt
        Decimal rfidCostINR = 0.00;

    if (opp.Project_capacity_in_MWp_including_Spare__c != null && opp.Project_capacity_in_MWp_including_Spare__c != 0 && opp.RFID_Readers_Qty__c != null) {
        rfidCostINR = (cm.RFIDreadercost__c * opp.RFID_Readers_Qty__c) /
                        (opp.Project_capacity_in_MWp_including_Spare__c * 1000000);
    }
    if(!ol.isEmpty()){
        data.outboundLogforattachment = ol;
    }

    data.rfidCostINR = rfidCostINR.setScale(2);
    data.rfidCostCents = (rfidCostINR * 100 /cm.Inland_Inr__c).setScale(2);

    // Module Overhead
        data.moduleOverheadCents = (cm.Overhead_cost_mdt__c).setScale(2);
        data.moduleOverheadINR = (cm.Overhead_cost_mdt__c * cm.Inland_Inr__c / 100).setScale(2);

    // Module Finance
    data.moduleFinanceCents = cm.Finance_Cost__c;
    data.moduleFinanceINR = (cm.Finance_Cost__c * inlandInr / 100).setScale(2);

    if (oli.DCR_Non_DCR1__c == 'NON-DCR') {
        data.cellBOMCents = 0;
        data.cellBOMINR = 0;
        data.cellOverheadCents = 0;
        data.cellOverheadINR = 0;
        data.cellFinanceCents = 0;
        data.cellFinanceINR = 0;
    } else {
        data.cellBOMCents = (cm.Cell_BOM_Cost__c).setScale(2);
        data.cellBOMINR = (cm.Cell_BOM_Cost__c * inlandInr / 100).setScale(2);
        data.cellOverheadCents = (cm.Cell_Overhead_Cost__c).setScale(2);
        data.cellOverheadINR = (cm.Cell_Overhead_Cost__c * inlandInr / 100).setScale(2);
        data.cellFinanceCents = (cm.Cell_Finance_Cost__c).setScale(2);
        data.cellFinanceINR = (cm.Cell_Finance_Cost__c * inlandInr / 100).setScale(2);
    }

    // Warranty / ABG / B Grade / etc.
    data.warrantyInsurance = cm.ModuleWarrantyInsurance__c;
    data.thirdpartywarranty = opp.Third_Party_Warranty_Insurance__c;
    data.rbi = cm.Inland_Inr__c;
    data.cbitc = cm.USD_to_INR_CBITC__c;
    data.bgrademodulediscount = cm.B_Grade_Module_Discount__c;
    data.bgrademoduleyield = cm.B_Grade_Module_Yield__c;
    data.abgvalue = opp.ABG_Value__c;
    data.abgpbgcost = cm.ABGPBGCostPA__c;
    data.abgvalidity = opp.ABG_Validity_Days__c;
    data.projectcapacity = opp.Project_capacity_in_MWp_including_Spare__c;
    data.pbgvalue = opp.PBG_Value__c;
    data.pbgvalidity = opp.PBG_Validity_Days__c;
    data.paymenttrembalance = opp.Payment_Term_Balance__c;


    if(opp.Domestic_Exports__c == 'Domestic')
    {
    data.outboundlogisticsINR = 0.00;
    data.outboundlogisticsCent = 0.00;
    if(opp.Incoterms__c != 'EXW'){
    if(!ol.isEmpty() && opp.Project_capacity_in_MWp_including_Spare__c!=null && oli.Product2.Wp__c!=null && oli.Product2.Pallet_Factor__c!=null && opp.Vehicle_Preference_if_any1__c!=null && opp.PalletBasedOnVehicle__c !=null){
    Decimal rawModules = (opp.Project_capacity_in_MWp_including_Spare__c * 1000000)/oli.Product2.Wp__c;
    Integer noModules = (Integer)Math.round(rawModules);
    Decimal rawPalletsReq = noModules/oli.Product2.Pallet_Factor__c;
    Integer noPalletsReq = (Integer)Math.round(rawPalletsReq);
    String vehiclePref = opp.PalletBasedOnVehicle__c;
    Integer vehicleCount = Integer.valueOf(vehiclePref);
    Decimal rawTrucksReq = noPalletsReq/vehicleCount;
    Integer noTrucksReq = (Integer)Math.round(rawTrucksReq);
    data.noTrucksReq = noTrucksReq;
    Decimal totalLogisticCost = noTrucksReq * ol[0].Distance_in_kms__c * ol[0].Price_Km__c;
    Decimal logisticCostPerWp = totalLogisticCost/(opp.Project_capacity_in_MWp_including_Spare__c * 1000000);
    data.outboundlogisticsINR = logisticCostPerWp.setScale(2, RoundingMode.HALF_UP);
    }
    
    Decimal outboundlogisticsCent = data.outboundlogisticsINR/cm.USD_to_INR_CBITC__c*100;
    data.outboundlogisticsCent = outboundlogisticsCent.setScale(2, RoundingMode.HALF_UP);
    }

    data.exportfreightchargesCent = 0.00;
    data.exportfreightchargesINR = 0.00;
}else{
    data.outboundlogisticsINR = 0.00;
    data.outboundlogisticsCent = 0.00;
    data.exportfreightchargesCent = inboundlogic[0].Export_Freight_Charges__c;
    Decimal exportfreightchargesINR = data.exportfreightchargesCent*cm.Inland_Inr__c /100;
    data.exportfreightchargesINR = exportfreightchargesINR.setScale(2, RoundingMode.HALF_UP);
}
data.freight = inboundlogic[0].Export_Freight_Charges__c;
data.paymentterm =opp.Payment_Terms__c != null ? opp.Payment_Terms__c: 0.00;
data.lcinterestcost = cm.LCinterestcostPA__c;
data.lcusanceperiod = opp.LC_Usance_Period_in_Days__c!=null? opp.LC_Usance_Period_in_Days__c:'0';
data.insurancepremiumcost = cm.InsurnacePremiumcost__c;

if(oli.DCR_Non_DCR1__c == 'DCR'){
    if(!cms.isEmpty()){
            data.ebitda = cms[0].DCR__c;
    }else{
        data.ebitda = 0;
    }
        
}else{
    if(!cms.isEmpty()){
        data.ebitda = cms[0].NDCR__c;
        }else{
            data.ebitda = 0;
        }
}

    resultMap.put(oli.Id, data);
}

return resultMap;
}
}
@AuraEnabled(cacheable=true)
public static Map<Id, List<RawMaterialWrapper>> RawMaterial(Id opportunityId, String pricingType, String countrySource) {
Map<Id, List<RawMaterialWrapper>> resultMap = new Map<Id, List<RawMaterialWrapper>>();

pricingType = String.isBlank(pricingType) ? 'Average Price' : pricingType;
countrySource = String.isBlank(countrySource) ? 'India' : countrySource;
    Opportunity opp = [Select Id,Wattage_Wp_Cell_Module1__c,Domestic_Exports__c,National_Head_Approval__c,PricingRawJSON__c from Opportunity where Id=:opportunityId];


List<OpportunityLineItem> oppLineItems = [
    SELECT Id, Product2Id, Product2.Name,DCR_Non_DCR1__c, Wattage_Wp_Cell_Module1__c
    FROM OpportunityLineItem 
    WHERE OpportunityId = :opportunityId
];
if (oppLineItems.isEmpty()) return resultMap;

    if (opp.National_Head_Approval__c == 'Approved' || opp.National_Head_Approval__c == 'Escalated') {
        Map<String, Object> jsonMap = (Map<String, Object>) JSON.deserializeUntyped(opp.PricingRawJSON__c);
            List<RawMaterialWrapper> wrapperList = new List<RawMaterialWrapper>();

    for (OpportunityLineItem oli : oppLineItems) {
        RawMaterialWrapper wrapper = new RawMaterialWrapper();
        wrapper.jsonRows = jsonMap;
        wrapper.isFromNH = true; 
        wrapperList.add(wrapper);
        resultMap.put(oli.Id, wrapperList);

    }
    return resultMap;
}

else{
    

Set<Id> productIds = new Set<Id>();
for (OpportunityLineItem oli : oppLineItems) {
    if (oli.Product2Id != null) productIds.add(oli.Product2Id);
    resultMap.put(oli.Id, new List<RawMaterialWrapper>());
}

List<Product_Raw_Materials__c> materials = [
    SELECT Id, Net_BoQ__c,DCR_Net_BoQ__c, Raw_Materials__r.Sort__c, Is_Variable__c,Skip_by_defualt__c,Product_Raw_Materials__c,
                Raw_Materials__r.Name, Raw_Materials__r.UOM__c,Raw_Materials__r.Is_Pallet_Raw_Material__c,
                Raw_Materials__r.China_Low_Price__c, Raw_Materials__r.China_Average_Price__c,
                Raw_Materials__r.India_Low_Price__c, Raw_Materials__r.India_Average_Price__c,
                Raw_Materials__r.Vietnam_Average_Price__c, Raw_Materials__r.Vietnam_Low_Price__c,
                Raw_Materials__r.Malaysia_Average_Price__c, Raw_Materials__r.Malaysia_Low_Price__c,
                Raw_Materials__r.Qty_20_Ft__c, Raw_Materials__r.Qty_40_Ft__c,
                Raw_Materials__r.Select_Raw_Material_Type__c, Raw_Materials__r.Cell_wattage__c,
                Raw_Materials__r.China_ADD__c, Raw_Materials__r.China_AIDC__c,
                Raw_Materials__r.China_BCD__c, Raw_Materials__r.China_CVD__c, 
                Raw_Materials__r.China_SWS__c, Raw_Materials__c, Product__c,Raw_Materials__r.Is_Sourced_from_India__c
            FROM Product_Raw_Materials__c
    WHERE Product__c IN :productIds
    ORDER BY Raw_Materials__r.Sort__c ASC
];

Map<Id, List<Product_Raw_Materials__c>> materialsByProduct = new Map<Id, List<Product_Raw_Materials__c>>();
for (Product_Raw_Materials__c rm : materials) {
    if (!materialsByProduct.containsKey(rm.Product__c)) {
        materialsByProduct.put(rm.Product__c, new List<Product_Raw_Materials__c>());
    }
    materialsByProduct.get(rm.Product__c).add(rm);
}
Input_Admin__mdt adminSettings = [SELECT USD_to_INR_CBITC__c, InsurnacePremiumcost__c ,Pallet_Module__c
                                        FROM Input_Admin__mdt 
                                        WHERE MasterLabel = 'default' LIMIT 1];
    Decimal usdToInrRate = adminSettings?.USD_to_INR_CBITC__c ?? 0;
    Decimal insurancePercent = adminSettings?.InsurnacePremiumcost__c ?? 0;

    
    List<String> requiredCountries = new List<String>{'India'};
    if (countrySource != 'India') requiredCountries.add(countrySource);



for (OpportunityLineItem oli : oppLineItems) {
    Decimal wattageValue = Decimal.valueof(oli.Wattage_Wp_Cell_Module1__c) ?? 0;
    List<Product_Raw_Materials__c> lineMaterials = materialsByProduct.get(oli.Product2Id);
    List<RawMaterialWrapper> wrapperList = new List<RawMaterialWrapper>();
    if (lineMaterials != null) {
        for (Product_Raw_Materials__c rm : lineMaterials) {
            RawMaterialWrapper wrapper = new RawMaterialWrapper();
            wrapper.opportunityLineItemId = oli.Id;
            wrapper.productName = oli.Product2.Name;
            wrapper.rawMaterialName = rm.Raw_Materials__r?.Name;
            wrapper.uom = rm.Raw_Materials__r?.UOM__c;
            wrapper.pricingType = pricingType;
            wrapper.countrySource = countrySource;
            wrapper.isVariable = rm.Is_Variable__c;
            wrapper.isDefaultSkip = rm.Skip_by_defualt__c;
            wrapper.defaultVariantGroupId = rm.Product_Raw_Materials__c; 
            wrapper.rawMaterialId = rm.Id;
            wrapper.picklistvalue = rm.Raw_Materials__r?.Select_Raw_Material_Type__c;
            wrapper.qty40Ft = rm.Raw_Materials__r?.Qty_40_Ft__c ?? 0;
            wrapper.qty20Ft = rm.Raw_Materials__r?.Qty_20_Ft__c ?? 0;
            wrapper.cellWattage = rm.Raw_Materials__r?.Cell_wattage__c ?? 0;
            wrapper.chinaAdd = rm.Raw_Materials__r?.China_ADD__c ?? 0;
            wrapper.chinaAidc = rm.Raw_Materials__r?.China_AIDC__c ?? 0;
            wrapper.chinaBcd = rm.Raw_Materials__r?.China_BCD__c ?? 0;
            wrapper.chinaCvd = rm.Raw_Materials__r?.China_CVD__c ?? 0;
            wrapper.chinaSws = rm.Raw_Materials__r?.China_SWS__c ?? 0;


            // pick appropriate NetBoQ field based on DCR/Non DCR per line item
            if (oli.DCR_Non_DCR1__c == 'NON-DCR') {
                wrapper.netBoQData = rm.Net_BoQ__c != null ? rm.Net_BoQ__c : 0;
                
            } else {
                wrapper.netBoQData = rm.DCR_Net_BoQ__c != null ? rm.DCR_Net_BoQ__c : 0;
            }
            Decimal logistics = 0.00;
            if(rm.Raw_Materials__r.Is_Sourced_from_India__c != true){
                logistics = calculateLogistics(rm, wrapper,countrySource);
            }else{
                logistics = 0.00;
            }
            

        for (String country : requiredCountries) {
            CountryData cd = new CountryData();
            cd.priceUsed = calculatePrice(rm, country, country == 'India' ? 'Average Price' : pricingType);
            if (wrapper.netBoQData != null && cd.priceUsed != null) {
                    cd.rawCostUSD = (wrapper.netBoQData * cd.priceUsed).setScale(2);
                } else {
                    cd.rawCostUSD = 0;
                }

            if(rm.Raw_Materials__r.Is_Sourced_from_India__c != true){
                cd.rawCostINR = (cd.rawCostUSD * usdToInrRate).setScale(2);
            }else{
                cd.rawCostINR = cd.rawCostUSD; 
            }
            

            cd.logistics = logistics;
            cd.insurance = ((cd.rawCostINR + cd.logistics) * (insurancePercent / 100)).setScale(2);
            if(opp.Domestic_Exports__c == 'Exports'){
                cd.totalMargin = 0;
            }else{
                cd.totalMargin = calculateDuty(wrapper, cd, country, usdToInrRate,opp,oli);
            }
            if(rm.Raw_Materials__r.Is_Pallet_Raw_Material__c!=true){
                cd.totalWithMargin = (cd.rawCostINR +cd.insurance+cd.logistics+ cd.totalMargin).setScale(2);
            }else{
            cd.totalWithMargin = ((cd.rawCostINR +cd.insurance+cd.logistics+ cd.totalMargin)/adminSettings.Pallet_Module__c).setScale(2);
            }

            if (wattageValue != 0) {
                cd.inrPerWatt = (cd.totalWithMargin / wattageValue).setScale(2);
                cd.usdPerWatt = (cd.inrPerWatt * 100 / usdToInrRate).setScale(2);
            }else{
                cd.inrPerWatt = 0.00;
                cd.usdPerWatt = 0.00;
            }

            wrapper.countryDataMap.put(country, cd);

            if (country == 'India') {
                setDisplayValues(wrapper, cd); // ✅ Show India by default
            } else if (country == countrySource) {
                // ✅ Add additional country's data to display
                setDisplayValues(wrapper, cd);
            }
        }


            wrapperList.add(wrapper);
        }
    }
    resultMap.put(oli.Id, wrapperList);
}

return resultMap;
    }
}
private static void setDisplayValues(RawMaterialWrapper wrapper, CountryData data) {
    wrapper.rawCostUSD = data.rawCostUSD;
    wrapper.rawCostINR = data.rawCostINR;
    wrapper.logisticsCalculation = data.logistics;
    wrapper.insurancePercentage = data.insurance;
    wrapper.actualPriceUsed = data.priceUsed;
    wrapper.totalCostWithMargin = data.totalMargin;
    wrapper.totalCostWithMarginAdded = data.totalWithMargin;
    wrapper.rawCostINRPerWattage = data.inrPerWatt;
    wrapper.rawCostUSDPerWattage = data.usdPerWatt;
}
private static Decimal calculatePrice(Product_Raw_Materials__c rm, String country, String pricingType) {
    if(rm.Raw_Materials__r.Is_Sourced_from_India__c != true){
    if (country == 'China') {
        return pricingType == 'Average Price' ? rm.Raw_Materials__r?.China_Average_Price__c :
                                                rm.Raw_Materials__r?.China_Low_Price__c;
    } else if (country == 'Malaysia') {
        return pricingType == 'Average Price' ? rm.Raw_Materials__r?.Malaysia_Average_Price__c :
                                                rm.Raw_Materials__r?.Malaysia_Low_Price__c;
    } else if (country == 'Vietnam') {
        return pricingType == 'Average Price' ? rm.Raw_Materials__r?.Vietnam_Average_Price__c :
                                                rm.Raw_Materials__r?.Vietnam_Low_Price__c;
    } else 
    {
        return pricingType == 'Average Price' ? rm.Raw_Materials__r?.India_Average_Price__c :
                                                rm.Raw_Materials__r?.India_Low_Price__c;
    }
    }
    
    else
    {
        
        return pricingType == 'Average Price' ? rm.Raw_Materials__r?.India_Average_Price__c :
                                                rm.Raw_Materials__r?.India_Low_Price__c;

    }

}

private static Decimal calculateLogistics(Product_Raw_Materials__c rm, RawMaterialWrapper wrapper,String countrySource) {
    Input_Admin__mdt cm = [
    SELECT Id, Inland_Inr__c, USD_to_INR_CBITC__c, RFIDreadercost__c,Finance_Cost__c
    FROM Input_Admin__mdt WHERE MasterLabel = 'default' LIMIT 1
];
    Freight_Charges__mdt fc;
    if(countrySource == 'China'){
        fc  = [SELECT Id,DeveloperName,Sea_Frieght_USD_20Ft__c,Sea_Frieght_USD_40Ft__c,Inland_Transport_INR_20Ft__c,Inland_Transport_INR_40Ft__c from Freight_Charges__mdt  where DeveloperName='China'];
    }else if(countrySource == 'Malaysia'){
        fc  = [SELECT Id,DeveloperName,Sea_Frieght_USD_20Ft__c,Sea_Frieght_USD_40Ft__c,Inland_Transport_INR_20Ft__c,Inland_Transport_INR_40Ft__c from Freight_Charges__mdt  where DeveloperName='Malaysia'];
    }else if(countrySource == 'Vietnam'){
    fc  = [SELECT Id,DeveloperName,Sea_Frieght_USD_20Ft__c,Sea_Frieght_USD_40Ft__c,Inland_Transport_INR_20Ft__c,Inland_Transport_INR_40Ft__c from Freight_Charges__mdt  where DeveloperName='Vietnam']; 
    }else{
    fc  = [SELECT Id,DeveloperName,Sea_Frieght_USD_20Ft__c,Sea_Frieght_USD_40Ft__c,Inland_Transport_INR_20Ft__c,Inland_Transport_INR_40Ft__c from Freight_Charges__mdt  where DeveloperName='China'];
    }
    decimal seaFreight40 = fc.Sea_Frieght_USD_40Ft__c ?? 0;
    decimal seaFreight20 = fc.Sea_Frieght_USD_20Ft__c ?? 0;
    decimal exchangeRate = cm.USD_to_INR_CBITC__c ?? 0;
    decimal inlandTransport40 = fc.Inland_Transport_INR_40Ft__c ?? 0;
    decimal inlandTransport20 = fc.Inland_Transport_INR_20Ft__c ?? 0;

    decimal inputLogistics = (seaFreight40 * exchangeRate) + inlandTransport40;
    Decimal input20FT = (seaFreight20*exchangeRate)+inlandTransport20;
    if (wrapper.picklistvalue == 'Glass') {
        return (wrapper.qty20Ft != 0) ? ((input20FT / wrapper.qty20Ft)).setScale(2) : 0;
    } else if (wrapper.picklistvalue == 'Cells') {
        return (wrapper.qty40Ft != 0 && wrapper.cellWattage != 0) ?
                ((inputLogistics / wrapper.qty40Ft) * (wrapper.netBoQData / wrapper.cellWattage)).setScale(2) : 0;
    } else {
        return (wrapper.qty40Ft != 0) ? ((inputLogistics / wrapper.qty40Ft) * wrapper.netBoQData).setScale(2) : 0;
    }
}

private static Decimal calculateDuty(RawMaterialWrapper wrapper, CountryData data, String country, Decimal usdRate, Opportunity opp,OpportunityLineItem oli) {
    //if (country != 'China') return 0;
    Input_Admin__mdt cm = [
    SELECT Id, Inland_Inr__c, USD_to_INR_CBITC__c, RFIDreadercost__c,Finance_Cost__c,Cell_Finance_Cost__c
    FROM Input_Admin__mdt WHERE MasterLabel = 'default' LIMIT 1
];

    if ((wrapper.picklistvalue == 'Wafer' || wrapper.picklistvalue == 'Cells' || wrapper.picklistvalue == 'Junction Box') && opp.Domestic_Exports__c == 'Domestic') {
        return(((data.rawCostINR + data.logistics + data.insurance)*(wrapper.chinaBcd/100))+
                (((data.rawCostINR + data.logistics + data.insurance)*(wrapper.chinaBcd/100))*(wrapper.chinaSws/100))+
                ((data.rawCostINR + data.logistics + data.insurance)*(wrapper.chinaAidc/100))+
                ((data.rawCostINR + data.logistics + data.insurance)*(wrapper.chinaCvd/100))+
                ((data.rawCostINR + data.logistics + data.insurance)*wrapper.chinaAdd)).setScale(2);
    }
        if((wrapper.picklistvalue == 'EVA Front' || wrapper.picklistvalue == 'EPE Front' || wrapper.picklistvalue == 'Busbar'|| wrapper.picklistvalue == 'Backsheet' || wrapper.picklistvalue == 'Interconnect'||wrapper.picklistvalue == 'RTV'|| wrapper.picklistvalue =='Potting Glue') && opp.Domestic_Exports__c == 'Domestic'){
        return(((data.rawCostINR + data.logistics + data.insurance)*(wrapper.chinaBcd/100))+
                (((data.rawCostINR + data.logistics + data.insurance)*(wrapper.chinaBcd/100))*(wrapper.chinaSws/100))+
                ((data.rawCostINR + data.logistics + data.insurance)*(wrapper.chinaAidc/100))+
                ((data.rawCostINR + data.logistics + data.insurance)*(wrapper.chinaCvd/100))+wrapper.chinaAdd*usdRate*wrapper.netBoQData).setScale(2);
    }
    
    if( wrapper.picklistvalue == 'Glass' && opp.Domestic_Exports__c == 'Domestic'){
        return((wrapper.chinaAdd*usdRate)-
        (data.rawCostINR + data.logistics + data.insurance)-
        (((data.rawCostINR + data.logistics + data.insurance)*(wrapper.chinaBcd/100))+
        (((data.rawCostINR + data.logistics + data.insurance)*(wrapper.chinaBcd/100))*(wrapper.chinaSws/100))+
        ((data.rawCostINR + data.logistics + data.insurance)*(wrapper.chinaAidc/100))+
        ((data.rawCostINR + data.logistics + data.insurance)*(wrapper.chinaCvd/100)))).setScale(2);
    
    }
    if( wrapper.picklistvalue == 'Al. Frame' && opp.Domestic_Exports__c == 'Domestic'){
        return((((data.rawCostINR + data.logistics + data.insurance)*(wrapper.chinaBcd/100))+
                (((data.rawCostINR + data.logistics + data.insurance)*(wrapper.chinaBcd/100))*(wrapper.chinaSws/100))+
                ((data.rawCostINR + data.logistics + data.insurance)*(wrapper.chinaAidc/100))+
                ((data.rawCostINR + data.logistics + data.insurance)*(wrapper.chinaCvd/100))+
                wrapper.chinaAdd*usdRate/100*Integer.valueof(oli.Wattage_Wp_Cell_Module1__c))*wrapper.netBoQData

        ).setScale(2);
    
    }

        return 0;
    
}

}