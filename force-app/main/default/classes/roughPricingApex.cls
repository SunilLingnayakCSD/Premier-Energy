public class roughPricingApex {
    @AuraEnabled(cacheable=true)
    public static String getUserProfileName(String userId){
       Id profileId = [SELECT ProfileId FROM User WHERE Id = :userId].ProfileId;
       String profilename =[SELECT Name FROM Profile WHERE Id = :profileId].Name;
        return profilename;
    }
    @AuraEnabled
    public static void createVariables(String oppId, String oldRM, String newRM){
      
      List<Opportunity> opp = [Select Id from Opportunity where Id =:oppId];
      List<OpportunityLineItem> oppLineItems = [SELECT Id FROM OpportunityLineItem WHERE OpportunityId = :opp];

        Product_Raw_Material_Tracking__c prmt = new Product_Raw_Material_Tracking__c();
        prmt.Opportunity_Product__c = oppLineItems[0].Id;
        prmt.Old_Product_Raw_Materials__c = oldRM;
        prmt.New_Product_Raw_Materials__c = newRM;
        Insert prmt;
        System.debug('prmt-->'+prmt);
    }
   
    @AuraEnabled(cacheable=true)
public static List<Id> checkVariables(String oppId, List<Id> rawMaterialIds) {
    // Get OpportunityLineItem Ids for the given Opportunity
    List<OpportunityLineItem> oppLineItems = [
        SELECT Id FROM OpportunityLineItem WHERE OpportunityId = :oppId
    ];

    if (oppLineItems.isEmpty() || rawMaterialIds.isEmpty()) {
        return new List<Id>();
    }

    Set<Id> oliIds = new Set<Id>();
    for (OpportunityLineItem oli : oppLineItems) {
        oliIds.add(oli.Id);
    }

    // Query Product_Raw_Material_Tracking__c records for these OLIs and Raw Material IDs
    List<Product_Raw_Material_Tracking__c> prmtList = [
        SELECT Id, New_Product_Raw_Materials__c, Old_Product_Raw_Materials__c, Opportunity_Product__c, CreatedDate
        FROM Product_Raw_Material_Tracking__c
        WHERE (New_Product_Raw_Materials__c IN :rawMaterialIds OR Old_Product_Raw_Materials__c IN :rawMaterialIds)
        AND Opportunity_Product__c IN :oliIds
        ORDER BY CreatedDate DESC
    ];

    // Build a Map to track latest New_Product_Raw_Materials__c for each rawMaterialId and Opportunity_Product__c
    Map<String, Product_Raw_Material_Tracking__c> latestPrmtMap = new Map<String, Product_Raw_Material_Tracking__c>();

    for (Product_Raw_Material_Tracking__c prmt : prmtList) {
        for (Id rmId : rawMaterialIds) {
            if (prmt.New_Product_Raw_Materials__c == rmId || prmt.Old_Product_Raw_Materials__c == rmId) {
                String key = rmId + '-' + prmt.Opportunity_Product__c;

                // Only add latest based on CreatedDate (as records are already ordered DESC)
                if (!latestPrmtMap.containsKey(key)) {
                    latestPrmtMap.put(key, prmt);
                }
            }
        }
    }

    // Prepare final result list
    List<Id> newProductRawMaterialsSet = new List<Id>();
    for (Product_Raw_Material_Tracking__c prmt : latestPrmtMap.values()) {
        if (prmt.New_Product_Raw_Materials__c != null) {
            newProductRawMaterialsSet.add(prmt.New_Product_Raw_Materials__c);
        }
    }

    return newProductRawMaterialsSet;
}

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
    @AuraEnabled public Decimal bgrademodulediscount;
    @AuraEnabled public Decimal bgrademoduleyield;
    @AuraEnabled public Decimal abgvalue;
    @AuraEnabled public Decimal abgpbgcost;
    @AuraEnabled public String abgvalidity;
    @AuraEnabled public Decimal projectcapacity;
    @AuraEnabled public Decimal pbgvalue;
    @AuraEnabled public String pbgvalidity;
    @AuraEnabled public Decimal outboundlogisticsINR;
    @AuraEnabled public Decimal outboundlogisticsCent;
    @AuraEnabled public Decimal exportfreightchargesCent;
    @AuraEnabled public Decimal exportfreightchargesINR;
    @AuraEnabled public Decimal paymentterm;
    @AuraEnabled public Decimal lcinterestcost;
    @AuraEnabled public String lcusanceperiod;
    @AuraEnabled public Decimal ebitda;
    @AuraEnabled public Decimal insurancepremiumcost;
    @AuraEnabled public Decimal rbi;
    @AuraEnabled public Decimal cbitc;

}

   @AuraEnabled(cacheable=true)
public static CostDataWrapper getAdminInputs(String oppId) {
   
    Input_Admin__mdt cm = [SELECT Id, MasterLabel, DeveloperName, Inland_Inr__c,USD_to_INR_CBITC__c,
        RFIDreadercost__c, Overhead_cost_mdt__c, Finance_Cost__c,ABGPBGCostPA__c,LCinterestcostPA__c,InsurnacePremiumcost__c,
        Cell_BOM_Cost__c, Cell_Finance_Cost__c, Cell_Overhead_Cost__c, ModuleWarrantyInsurance__c,B_Grade_Module_Discount__c,B_Grade_Module_Yield__c
        FROM Input_Admin__mdt
        WHERE MasterLabel = 'default'
        LIMIT 1];

    Opportunity opp = [SELECT Id, RFID_Readers_Qty__c, Ship_to__r.Pincode__c,Ship_to__r.State__c, Project_capacity_in_MWp_including_Spare__c, DCR_Non_DCR__c,LC_Usance_Period_in_Days__c,
    ABG_Value__c,ABG_Validity__c,PBG_Value__c,PBG_Validity__c,Domestic_Exports__c,Payment_Terms__c,Segment__c,Plant_Name__c ,Wattage_Wp_Cell_Module__c,Vehicle_Preference_if_any__c
        FROM Opportunity WHERE Id = :oppId];

         List<OpportunityLineItem> oppLineItems = [SELECT Id,Product2.Wp__c,Product2.Pallet_Factor__c FROM OpportunityLineItem WHERE OpportunityId = :oppId Limit 1];

        List<Plant_with_Pincode__mdt> pc = [Select Id,Plant_Pincode__c,MasterLabel from Plant_with_Pincode__mdt where MasterLabel=:opp.Plant_Name__c];
        List<Outbound_Logistic__c> ol = new List<Outbound_Logistic__c>();
        if(!pc.isEmpty()){
        ol = [Select Id,Customer_Pincode__c,Plant_Pincode__c,Distance_in_kms__c,State__c,Price_Km__c from Outbound_Logistic__c
         where Customer_Pincode__c=:Integer.valueof(opp.Ship_to__r.Pincode__c) and Plant_Pincode__c=:pc[0].Plant_Pincode__c and State__c=: opp.Ship_to__r.State__c];
        }

 List<Segment__mdt> cms = [SELECT Id, MasterLabel, DeveloperName,DCR__c,NDCR__c FROM Segment__mdt WHERE MasterLabel =: opp.Segment__c LIMIT 1];

 List<Input_Inbound_Logistics__mdt> inboundlogic= [Select Id,MasterLabel,Export_Freight_Charges__c,DeveloperName  from Input_Inbound_Logistics__mdt where DeveloperName ='Input_Inbound_Logists_fields'];


    CostDataWrapper result = new CostDataWrapper();

    Decimal rfidCostINR = 0.00;

        if (opp.Project_capacity_in_MWp_including_Spare__c != null && opp.Project_capacity_in_MWp_including_Spare__c != 0) {
            rfidCostINR = (cm.RFIDreadercost__c * opp.RFID_Readers_Qty__c) /
                            (opp.Project_capacity_in_MWp_including_Spare__c * 1000000);
        }

    result.rfidCostINR = rfidCostINR.setScale(2);
    result.rfidCostCents = (rfidCostINR * 100 /cm.Inland_Inr__c).setScale(2);

    result.moduleOverheadCents = (cm.Overhead_cost_mdt__c).setScale(2);
    result.moduleOverheadINR = (cm.Overhead_cost_mdt__c * cm.Inland_Inr__c / 100).setScale(2);

    result.moduleFinanceCents = (cm.Finance_Cost__c).setScale(2);
    result.moduleFinanceINR = (cm.Finance_Cost__c * cm.Inland_Inr__c / 100).setScale(2);

    if (opp.DCR_Non_DCR__c == 'Non DCR') {
        result.cellBOMCents = 0.00;
        result.cellBOMINR = 0.00;
        result.cellOverheadCents = 0.00;
        result.cellOverheadINR = 0.00;
        result.cellFinanceCents = 0.00;
        result.cellFinanceINR = 0.00;
    } else {
        result.cellBOMCents = (cm.Cell_BOM_Cost__c).setScale(2);
        result.cellBOMINR = (cm.Cell_BOM_Cost__c * cm.Inland_Inr__c / 100).setScale(2);

        result.cellOverheadCents = (cm.Cell_Overhead_Cost__c).setScale(2);
        result.cellOverheadINR = (cm.Cell_Overhead_Cost__c * cm.Inland_Inr__c / 100).setScale(2);

        result.cellFinanceCents = (cm.Cell_Finance_Cost__c).setScale(2);
        result.cellFinanceINR = (cm.Cell_Finance_Cost__c * cm.Inland_Inr__c / 100).setScale(2);
    }

    result.warrantyInsurance = cm.ModuleWarrantyInsurance__c;
    result.rbi = cm.Inland_Inr__c;
    result.cbitc = cm.USD_to_INR_CBITC__c;
    result.bgrademodulediscount = cm.B_Grade_Module_Discount__c;
    result.bgrademoduleyield = cm.B_Grade_Module_Yield__c;
    result.abgvalue = opp.ABG_Value__c;
    result.abgpbgcost = cm.ABGPBGCostPA__c;
    result.abgvalidity = opp.ABG_Validity__c;
    result.projectcapacity = opp.Project_capacity_in_MWp_including_Spare__c;
    result.pbgvalue = opp.PBG_Value__c;
    result.pbgvalidity = opp.PBG_Validity__c;

    if(opp.Domestic_Exports__c == 'Domestic')
	{
        result.outboundlogisticsINR = 0.00;
        if(!ol.isEmpty() && opp.Project_capacity_in_MWp_including_Spare__c!=null && oppLineItems[0].Product2.Wp__c!=null && oppLineItems[0].Product2.Pallet_Factor__c!=null && opp.Vehicle_Preference_if_any__c!=null)
		{
        Decimal rawModules = (opp.Project_capacity_in_MWp_including_Spare__c * 1000000)/oppLineItems[0].Product2.Wp__c;
        Integer noModules = (Integer)Math.round(rawModules);
        Decimal rawPalletsReq = noModules/oppLineItems[0].Product2.Pallet_Factor__c;
        Integer noPalletsReq = (Integer)Math.round(rawPalletsReq);
        Decimal rawTrucksReq = noPalletsReq/Integer.valueOf(opp.Vehicle_Preference_if_any__c);
        Integer noTrucksReq = (Integer)Math.round(rawTrucksReq);
        Decimal totalLogisticCost = noTrucksReq * ol[0].Distance_in_kms__c * ol[0].Price_Km__c;
        Decimal logisticCostPerWp = totalLogisticCost/1000000;
        result.outboundlogisticsINR = logisticCostPerWp.setScale(2, RoundingMode.HALF_UP);
        }
        
        Decimal outboundlogisticsCent = result.outboundlogisticsINR/cm.USD_to_INR_CBITC__c*100;
        result.outboundlogisticsCent = outboundlogisticsCent.setScale(2, RoundingMode.HALF_UP);
        result.exportfreightchargesCent = 0.00;
        result.exportfreightchargesINR = 0.00;
    }else{
        result.outboundlogisticsINR = 0.00;
        result.outboundlogisticsCent = 0.00;
        result.exportfreightchargesCent = inboundlogic[0].Export_Freight_Charges__c;
        Decimal exportfreightchargesINR = result.exportfreightchargesCent*cm.Inland_Inr__c /100;
        result.exportfreightchargesINR = exportfreightchargesINR.setScale(2, RoundingMode.HALF_UP);
    }

    result.paymentterm =opp.Payment_Terms__c != null ? opp.Payment_Terms__c: 0.00;
    result.lcinterestcost = cm.LCinterestcostPA__c;
    result.lcusanceperiod = opp.LC_Usance_Period_in_Days__c!=null? opp.LC_Usance_Period_in_Days__c:'0';
    result.insurancepremiumcost = cm.InsurnacePremiumcost__c;

    if(opp.DCR_Non_DCR__c == 'DCR'){
        if(!cms.isEmpty()){
             result.ebitda = cms[0].DCR__c;
        }else{
            result.ebitda = 0;
        }
           
    }else{
        if(!cms.isEmpty()){
            result.ebitda = cms[0].NDCR__c;
            }else{
                result.ebitda = 0;
            }
    }
    return result;
}

public class RawMaterialWrapper {
    
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
    public static List<RawMaterialWrapper> RawMaterial(Id opportunityId, String pricingType, String countrySource) {
        countrySource = String.isBlank(countrySource) ? 'India' : countrySource;
        pricingType = String.isBlank(pricingType) ? 'Average Price' : pricingType;
        Opportunity opp = [Select Id,Wattage_Wp_Cell_Module__c from Opportunity where Id=:opportunityId];

        List<OpportunityLineItem> oppLineItems = [
            SELECT Id, Product2Id,DCR_Non_DCR__c,Opportunity.Wattage_Wp_Cell_Module__c
            FROM OpportunityLineItem 
            WHERE OpportunityId = :opportunityId
            WITH SECURITY_ENFORCED
        ];
        if (oppLineItems.isEmpty()) return new List<RawMaterialWrapper>();

        Decimal wattageValue = Decimal.valueof(oppLineItems[0].Opportunity?.Wattage_Wp_Cell_Module__c) ?? 0;
        Set<Id> productIds = new Set<Id>();
        for (OpportunityLineItem oli : oppLineItems) {
            if (oli.Product2Id != null) productIds.add(oli.Product2Id);
        }

        Map<String, Product_Raw_Materials__c> materialMap = new Map<String, Product_Raw_Materials__c>();
        for (Product_Raw_Materials__c rm : [
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
        ]) {
            String uniqueKey = rm.Raw_Materials__c + '-' + rm.Product__c;
            if (materialMap.containsKey(uniqueKey)) {
                Product_Raw_Materials__c existing = materialMap.get(uniqueKey);
                existing.Net_BoQ__c += rm.Net_BoQ__c;
            } else {
                materialMap.put(uniqueKey, rm);
            }
        }

        Input_Admin__mdt adminSettings = [SELECT USD_to_INR_CBITC__c, InsurnacePremiumcost__c ,Pallet_Module__c
                                         FROM Input_Admin__mdt 
                                         WHERE MasterLabel = 'default' LIMIT 1];
        Decimal usdToInrRate = adminSettings?.USD_to_INR_CBITC__c ?? 0;
        Decimal insurancePercent = adminSettings?.InsurnacePremiumcost__c ?? 0;

        List<RawMaterialWrapper> wrapperList = new List<RawMaterialWrapper>();
        List<String> requiredCountries = new List<String>{'India'};
        if (countrySource != 'India') requiredCountries.add(countrySource);

        for (Product_Raw_Materials__c rm : materialMap.values()) {
            RawMaterialWrapper wrapper = new RawMaterialWrapper();
            wrapper.rawMaterialName = rm.Raw_Materials__r?.Name ?? 'N/A';
            wrapper.uom = rm.Raw_Materials__r?.UOM__c ?? 'N/A';
            if(opp.DCR_Non_DCR__c == 'Non DCR'){
                wrapper.netBoQData = rm.Net_BoQ__c != null ? rm.Net_BoQ__c : 0;
            }else{
                wrapper.netBoQData = rm.DCR_Net_BoQ__c != null ? rm.DCR_Net_BoQ__c : 0;
            }
            wrapper.rawMaterialId = rm.Id;
            wrapper.isVariable = rm.Is_Variable__c;
            wrapper.isDefaultSkip = rm.Skip_by_defualt__c;
            wrapper.defaultVariantGroupId = rm.Product_Raw_Materials__c; 
            wrapper.pricingType = pricingType;
            wrapper.countrySource = countrySource;

            wrapper.picklistvalue = rm.Raw_Materials__r?.Select_Raw_Material_Type__c;
            wrapper.qty40Ft = rm.Raw_Materials__r?.Qty_40_Ft__c ?? 0;
            wrapper.qty20Ft = rm.Raw_Materials__r?.Qty_20_Ft__c ?? 0;
            wrapper.cellWattage = rm.Raw_Materials__r?.Cell_wattage__c ?? 0;
            wrapper.chinaAdd = rm.Raw_Materials__r?.China_ADD__c ?? 0;
            wrapper.chinaAidc = rm.Raw_Materials__r?.China_AIDC__c ?? 0;
            wrapper.chinaBcd = rm.Raw_Materials__r?.China_BCD__c ?? 0;
            wrapper.chinaCvd = rm.Raw_Materials__r?.China_CVD__c ?? 0;
            wrapper.chinaSws = rm.Raw_Materials__r?.China_SWS__c ?? 0;

            Decimal logistics = calculateLogistics(rm, wrapper);

            for (String country : requiredCountries) {
                CountryData cd = new CountryData();
                cd.priceUsed = calculatePrice(rm, country, country == 'India' ? 'Average Price' : pricingType);
                cd.rawCostUSD = (wrapper.netBoQData * cd.priceUsed).setScale(2);
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
                    cd.totalMargin = calculateDuty(wrapper, cd, country, usdToInrRate,opp);
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

        return wrapperList;
    }
    
    // ✅ Moved here to make it accessible
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
        } else {
            return pricingType == 'Average Price' ? rm.Raw_Materials__r?.India_Average_Price__c :
                                                    rm.Raw_Materials__r?.India_Low_Price__c;
        }
        }else{
            return pricingType == 'Average Price' ? rm.Raw_Materials__r?.India_Average_Price__c :
                                                    rm.Raw_Materials__r?.India_Low_Price__c;
        }
    }

    private static Decimal calculateLogistics(Product_Raw_Materials__c rm, RawMaterialWrapper wrapper) {
        Integer inputLogistics =0;
        Decimal input20FT = 0;

        if (wrapper.picklistvalue == 'Glass') {
            return (wrapper.qty20Ft != 0) ? ((input20FT / wrapper.qty20Ft) * wrapper.netBoQData).setScale(2) : 0;
        } else if (wrapper.picklistvalue == 'Cells') {
            return (wrapper.qty40Ft != 0 && wrapper.cellWattage != 0) ?
                   ((inputLogistics / wrapper.qty40Ft) * (wrapper.netBoQData / wrapper.cellWattage)).setScale(2) : 0;
        } else {
            return (wrapper.qty40Ft != 0) ? ((inputLogistics / wrapper.qty40Ft) * wrapper.netBoQData).setScale(2) : 0;
        }
    }

    private static Decimal calculateDuty(RawMaterialWrapper wrapper, CountryData data, String country, Decimal usdRate, Opportunity opp) {
        //if (country != 'China') return 0;

        if ((wrapper.picklistvalue == 'Wafer' || wrapper.picklistvalue == 'Cells' || wrapper.picklistvalue == 'Junction Box') && opp.Domestic_Exports__c == 'Domestic') {
            return(((data.rawCostINR + data.logistics + data.insurance)*(wrapper.chinaBcd/100))+
                    (((data.rawCostINR + data.logistics + data.insurance)*(wrapper.chinaBcd/100))*(wrapper.chinaSws/100))+
                    ((data.rawCostINR + data.logistics + data.insurance)*(wrapper.chinaAidc/100))+
                    ((data.rawCostINR + data.logistics + data.insurance)*(wrapper.chinaCvd/100))+
                    ((data.rawCostINR + data.logistics + data.insurance)*wrapper.chinaAdd)).setScale(2);
        }
         if((wrapper.picklistvalue == 'EVA Front' || wrapper.picklistvalue == 'EPE Front' || wrapper.picklistvalue == 'Backsheet'|| wrapper.picklistvalue == 'Interconnect' || wrapper.picklistvalue == 'Busbar' || wrapper.picklistvalue == 'RTV'|| wrapper.picklistvalue =='Potting Glue') && opp.Domestic_Exports__c == 'Domestic'){
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
                    wrapper.chinaAdd*usdRate/100*Integer.valueof(opp.Wattage_Wp_Cell_Module__c))*wrapper.netBoQData

            ).setScale(2);
        
        }

            return 0;
        

       // if (wrapper.netBoQData == 0) return 0;

       
    }

}