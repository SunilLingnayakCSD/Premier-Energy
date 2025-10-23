public class JobHandoverSummaryController {
    
    // Wrapper class to hold all form data
    public class HandoverSummaryWrapper {
        // Section A: Description
        public String customerName {get; set;}
        public String businessEntity {get; set;}
        public String domesticExport {get; set;}
        public String segment {get; set;}
        public String category {get; set;}
        public Decimal projectCapacityMW {get; set;}
        public Decimal quantity {get; set;}
        public String wattage {get; set;}
        public String productDetails {get; set;}
        public String deliveryTimelines {get; set;}
        public String incoterms {get; set;}
        public String generatedBy {get; set;}
        public String deliveryLocation {get; set;}
        public String dcrNondcr {get; set;}
        public String quotationName {get; set;}
        
        // Section B: Contract Agreement Details
        public String priceApprovalRef {get; set;}
        public String msaRef {get; set;}
        public String poRef {get; set;}
        public String loaRef {get; set;}
        public String otherDocuments {get; set;}
        public String transactionModality {get; set;}
        public String additionalScope {get; set;}
        public String customerSPOCName {get; set;}
        public String customerSPOCEmail {get; set;}
        public String customerSPOCPhone {get; set;}
        public String escalation1Name {get; set;}
        public String escalation1Email {get; set;}
        public String escalation1Phone {get; set;}
        public String siteSPOCName {get; set;}
        public String siteSPOCEmail {get; set;}
        public String siteSPOCPhone {get; set;}
        public String insuranceRequired {get; set;}
        public string claimPeriodDays {get; set;}
        public String vehicleType {get; set;}
        public Decimal freightCost {get; set;}
        public String detentionFreePeriod {get; set;}
        public String spareModule {get; set;}
        public String otherContractDetails {get; set;}
        
        // Section C: Technical Details
        public String cellTechnology {get; set;}
        public String bom {get; set;}
        public String dataSheet {get; set;}
        public String qap {get; set;}
        public String certification {get; set;}
        public String cableLength {get; set;}
        public String specialLabels {get; set;}
        public String rfidRequired {get; set;}
        public Decimal rfidReaderQty {get; set;}
        public String inlineInspection {get; set;}
        public String pdi {get; set;}
        
        // Section D: Price & Commercial Details
        public Decimal unitPrice {get; set;}
        public Decimal exchangeRate {get; set;}
        public Decimal contractValue {get; set;}
        public String paymentTerm {get; set;}
        public String lcDetails {get; set;}
        public String delayLD {get; set;}
        public String paymentStatus {get; set;}
        public String otherCommercialDetails {get; set;}
        
        // Section E: Additional Information
        public String additionalInformation {get; set;}
        public String supplyAgreement {get; set;}
        public String contractAgreement {get; set;}
        public String thirdPartyWarrantyInsurance {get; set;}
    }
    
    public HandoverSummaryWrapper wrapper {get; set;}
    public Opportunity currentOpportunity {get; set;}
    public String opportunityId {get; set;}
    
    public JobHandoverSummaryController() {
        opportunityId = ApexPages.currentPage().getParameters().get('recordId');
        
        if (String.isBlank(opportunityId)) {
            opportunityId = ApexPages.currentPage().getParameters().get('id');
        }

        System.debug('Final Opportunity ID: ' + opportunityId);
        initializeWrapper();
        loadOpportunityData();
    }
    
    private void initializeWrapper() {
        wrapper = new HandoverSummaryWrapper();
    }
    
    private void loadOpportunityData() {
        if(String.isNotBlank(opportunityId)) {
            try {
                System.debug('Opportunity ID from URL: ' + opportunityId);
                currentOpportunity = [SELECT Id, Name, Account.Name, Domestic_Exports__c, Segment1__c,
                                    Owner.Name, Amount, CloseDate, DCR_Non_DCR1__c, Project_capacity_in_MWp_including_Spare__c,
                                    Wattage_Wp_Cell_Module1__c, Incoterms__c, Payment_Terms1__c, Delay_LD1__c, QAP_Attachment__c,
                                    BOM_Attachment__c, Product_Details_Technology_Type1__c, Delivery_Required_by__c, Delivery_Location__c,
                                    Price_Approval_Reference__c, Contract_Agreement__c, Supply_Agreement__c, End_Customer_Name_if_any__c,
                                    Third_Party_Warranty_Insurance__c, RFID_Readers_Qty__c, Pre_Dispatch_Inspection__c, Vehicle_Detention_Holding_Period_Hrs__c,
                                    Exchange_Rate_INR_1_USD__c, Premier_Business_Entity1__c, Transaction_Modality__c, Inline_Inspection__c,
                                    Vehicle_Preference_if_any1__c, ReasonAdditional_Technical_Requirements1__c, Cable_length__c,
                                    Final_Wp_price__c, Discounted_Wp_Price__c, TotalOpportunityQuantity, Customer_SPOC_EMAIL__c,
                                    Contract_Order_Date__c, Purchase_Order_Contract_Reference__c, Customer_SPOC_Mobile_No__c,
                                    Customer_SPOC_Name__c, Data_Sheet_Attachment__c,Transit_Damage_Report_Claim_Period_Days__c,LC_reference__c,
                                    Total_Contract_Order_Value__c,Other_Details_Note__c,freight_cost__c
                                    FROM Opportunity WHERE Id = :opportunityId];
                
                System.debug('Queried Opportunity: ' + JSON.serializePretty(currentOpportunity));               
                
                // Map opportunity fields to wrapper
                if(currentOpportunity.Account != null) {
                    wrapper.customerName = currentOpportunity.Account.Name;
                }
                
                wrapper.domesticExport = currentOpportunity.Domestic_Exports__c;
                wrapper.segment = currentOpportunity.Segment1__c;
                wrapper.dcrNondcr = currentOpportunity.DCR_Non_DCR1__c;
                wrapper.projectCapacityMW = currentOpportunity.Project_capacity_in_MWp_including_Spare__c;
                wrapper.businessEntity = currentOpportunity.Premier_Business_Entity1__c;
                wrapper.wattage = currentOpportunity.Wattage_Wp_Cell_Module1__c;
                wrapper.quantity = currentOpportunity.TotalOpportunityQuantity;
                wrapper.incoterms = currentOpportunity.Incoterms__c;
                wrapper.paymentTerm = currentOpportunity.Payment_Terms1__c;
                wrapper.delayLD = currentOpportunity.Delay_LD1__c;
                wrapper.qap = currentOpportunity.QAP_Attachment__c;
                wrapper.bom = currentOpportunity.BOM_Attachment__c;
                wrapper.productDetails = currentOpportunity.Product_Details_Technology_Type1__c;
                wrapper.claimPeriodDays = currentOpportunity.Transit_Damage_Report_Claim_Period_Days__c;
                wrapper.vehicleType= currentOpportunity.Vehicle_Preference_if_any1__c;
                wrapper.lcDetails = currentOpportunity.LC_reference__c;
                wrapper.contractValue = currentOpportunity.Total_Contract_Order_Value__c;
                wrapper.exchangeRate = currentOpportunity.Exchange_Rate_INR_1_USD__c;
                wrapper.otherContractDetails = currentOpportunity.Other_Details_Note__c;
                wrapper.freightCost = currentOpportunity.freight_cost__c;
                
                if(currentOpportunity.Delivery_Required_by__c != null) {
                    Date deliveryDate = currentOpportunity.Delivery_Required_by__c;
                    DateTime deliveryDateTime = DateTime.newInstance(deliveryDate, Time.newInstance(0, 0, 0, 0));
                    wrapper.deliveryTimelines = deliveryDateTime.format('dd-MM-yyyy');
                }
                
                wrapper.deliveryLocation = currentOpportunity.Delivery_Location__c;
                wrapper.priceApprovalRef = currentOpportunity.Price_Approval_Reference__c;
                wrapper.supplyAgreement = currentOpportunity.Supply_Agreement__c;
                
                if(currentOpportunity.Contract_Order_Date__c != null) {
                    Date contractAgreementDate = currentOpportunity.Contract_Order_Date__c; 
                    DateTime contractAgreementDateTime = DateTime.newInstance(contractAgreementDate, Time.newInstance(0, 0, 0, 0));
                    wrapper.contractAgreement = contractAgreementDateTime.format('dd-MM-yyyy');
                }
                
                wrapper.customerSPOCName = currentOpportunity.Customer_SPOC_Name__c;
                wrapper.customerSPOCEmail = currentOpportunity.Customer_SPOC_EMAIL__c;
                wrapper.customerSPOCPhone = currentOpportunity.Customer_SPOC_Mobile_No__c;
                wrapper.poRef = currentOpportunity.Purchase_Order_Contract_Reference__c;
                wrapper.dataSheet = currentOpportunity.Data_Sheet_Attachment__c;
                wrapper.thirdPartyWarrantyInsurance = currentOpportunity.Third_Party_Warranty_Insurance__c;
                wrapper.detentionFreePeriod = currentOpportunity.Vehicle_Detention_Holding_Period_Hrs__c;
                wrapper.rfidReaderQty = currentOpportunity.RFID_Readers_Qty__c;
                wrapper.pdi = currentOpportunity.Pre_Dispatch_Inspection__c;
                wrapper.transactionModality = currentOpportunity.Transaction_Modality__c;
                wrapper.inlineInspection = currentOpportunity.Inline_Inspection__c;
                wrapper.vehicleType = currentOpportunity.Vehicle_Preference_if_any1__c;
                wrapper.certification = currentOpportunity.ReasonAdditional_Technical_Requirements1__c;
                wrapper.cableLength = currentOpportunity.Cable_length__c;
                
                if(currentOpportunity.Discounted_Wp_Price__c != null) {
                    wrapper.unitPrice = currentOpportunity.Discounted_Wp_Price__c;
                } else if(currentOpportunity.Final_Wp_price__c != null) {
                    wrapper.unitPrice = currentOpportunity.Final_Wp_price__c;
                }
                
                // Get quotation name
                wrapper.quotationName = getLatestQuotationName(opportunityId);
                
                System.debug('wrapper.unitPrice: ' + wrapper.unitPrice);
            } catch(Exception e) {
                System.debug('Error querying opportunity: ' + e.getMessage());
                ApexPages.addMessage(new ApexPages.Message(
                    ApexPages.Severity.ERROR, 'Error loading opportunity data: ' + e.getMessage()));
            }
        } else {
            ApexPages.addMessage(new ApexPages.Message(
                ApexPages.Severity.WARNING, 'No Opportunity ID provided'));
        }
    }
    
    private String getLatestQuotationName(String oppId) {
        try {
            List<Quote> quotes = [SELECT Name FROM Quote 
                                WHERE OpportunityId = :oppId 
                                ORDER BY CreatedDate DESC 
                                LIMIT 1];
            
            if(!quotes.isEmpty()) {
                return quotes[0].Name;
            }
        } catch(Exception e) {
            System.debug('Error fetching quotation: ' + e.getMessage());
        }
        return null;
    }
    
    public PageReference generatePDF() {
        PageReference pdfPage = Page.JobHandoverSummary; // Make sure this page exists
        pdfPage.getParameters().put('id', opportunityId);
        return pdfPage;
    }
    
    public PageReference saveToOpportunity() { // Fixed typo in method name
        try {
            if(currentOpportunity != null) {
                update currentOpportunity;
            }
            
            ApexPages.addMessage(new ApexPages.Message(
                ApexPages.Severity.CONFIRM, 'Data saved successfully'));
        } catch(Exception e) {
            ApexPages.addMessage(new ApexPages.Message(
                ApexPages.Severity.ERROR, 'Error saving data: ' + e.getMessage()));
        }
        return null;
    }
}