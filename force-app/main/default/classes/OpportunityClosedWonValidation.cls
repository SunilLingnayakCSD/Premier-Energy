public class OpportunityClosedWonValidation {
    
    public static void validate(List<Opportunity> newList, Map<Id, Opportunity> oldMap) {
        for (Opportunity opp : newList) {
            Opportunity oldOpp = oldMap.get(opp.Id);
            
            if (opp.StageName == 'Contract Agreement' &&
                (oldOpp == null || oldOpp.StageName != 'Contract Agreement')) {
                    
                    List<String> missingFields = new List<String>();
                    
                    // Standard Fields
                    if (String.isBlank(opp.Name)) missingFields.add('Opportunity Name');
                    if (opp.OwnerId == null) missingFields.add('Owner');
                    if (opp.CloseDate == null) missingFields.add('Close Date');
                    if (opp.AccountId == null) missingFields.add('Account Name');
                    if (String.isBlank(opp.Type)) missingFields.add('Type');
                    if (String.isBlank(opp.Region__c)) missingFields.add('Region');
                    if (opp.Capacity_in_MWp__c == null) missingFields.add('Capacity (in MWp)');
                    if (opp.EMD__c == null) missingFields.add('EMD');
                    if (opp.Bill_to__c == null) missingFields.add('Bill To');
                    if (opp.Billing_Address_with_GST__c == null) missingFields.add('Billing Address with GST');
                    if (opp.BOM__c == null) missingFields.add('BOM');
                    if (opp.Ship_to__c == null) missingFields.add('Ship To');
                    if (String.isBlank(opp.Controller_Type__c)) missingFields.add('Controller Type');
                    if (String.isBlank(opp.Plant_Name__c)) missingFields.add('Plant Name');
                    if (String.isBlank(opp.Product_Details__c)) missingFields.add('Product Details');
                    if (String.isBlank(opp.Segment__c)) missingFields.add('Segment');
                    if (String.isBlank(opp.Domestic_Exports__c)) missingFields.add('Domestic/Exports');
                    if (String.isBlank(opp.DCR_Non_DCR__c)) missingFields.add('DCR/Non-DCR');
                    if (String.isBlank(opp.Product_Details_Technology_Type__c)) missingFields.add('Technology Type');
                    if (String.isBlank(opp.Incoterms__c)) missingFields.add('Incoterms');
                    if (String.isBlank(opp.Inline_Inspection__c)) missingFields.add('Inline Inspection');
                    if (String.isBlank(opp.Third_Party_Lab_Testing_if_any__c)) missingFields.add('Third Party Lab Testing');
                    if (String.isBlank(opp.Pre_Dispatch_Inspection__c)) missingFields.add('Pre-Dispatch Inspection');
                    if (String.isBlank(opp.Region_Head_Email__c)) missingFields.add('Region Head Email');
                    if (String.isBlank(opp.Customer_Registered_Address__c)) missingFields.add('Customer Registered Address');
                    if (String.isBlank(opp.Customer_Role__c)) missingFields.add('Customer Role');
                    if (opp.Project_capacity_in_MWp_including_Spare__c == null) missingFields.add('Project Capacity (including Spare)');
                    if (opp.Wattage_Wp_Cell_Module__c == null) missingFields.add('Wattage Wp/Cell Module');
                    if (opp.Project_COD__c == null) missingFields.add('Project COD');
                    if (opp.Pipeline_Projects_Capacity_in_MWp__c == null) missingFields.add('Pipeline Projects Capacity (MWp)');
                    if (opp.Serial_Defect_Liability__c == null) missingFields.add('Serial Defect Liability');
                    if (opp.Production_Period__c == null) missingFields.add('Production Period');
                    if (opp.Manufacturing_Warranty_in_Years__c == null) missingFields.add('Manufacturing Warranty (Years)');
                    if (opp.Performance_Warranty_in_Years__c == null) missingFields.add('Performance Warranty (Years)');
                    
                    // Custom Fields
                    if (opp.Commercial_Deviations__c == null || opp.Commercial_Deviations__c != true) {
                        missingFields.add('Commercial Deviations must be TRUE');
                    }
                    
                    // New Fields
                    if (String.isBlank(opp.ABG__c)) missingFields.add('ABG');
                    if (opp.ABG_Expiry_Date__c == null) missingFields.add('ABG Expiry Date');
                    if (opp.ABG_Issuance_Date__c == null) missingFields.add('ABG Issuance Date');
                    if (String.isBlank(opp.ABG_Reference__c)) missingFields.add('ABG Reference');
                    if (String.isBlank(opp.ABG_Status__c)) missingFields.add('ABG Status');
                    if (String.isBlank(opp.ABG_Validity__c)) missingFields.add('ABG Validity');
                    if (opp.End_Customer_Name_if_any__c == null) missingFields.add('End-Customer Name (if any)');
                    if (opp.ABG_Value__c == null) missingFields.add('ABG Value');
                    if (opp.Additional_Technical_Requirements__c == null) missingFields.add('Additional Technical Requirements');
                    if (opp.Advance_Payment__c == null) missingFields.add('Advance Payment');
                    if (opp.Amount == null) missingFields.add('Amount');
                    if (opp.Anti_Bribery_Corruption__c == null) missingFields.add('Anti-Bribery & Corruption');
                    if (String.isBlank(opp.Attach_Signed_Document__c)) missingFields.add('Attach Signed Document');
                    if (opp.Audit_Requirements_if_any__c == null) missingFields.add('Audit Requirements');
                    if (String.isBlank(opp.Bid_Submission_Acknowledgement__c)) missingFields.add('Bid Submission Acknowledgement');
                    if (opp.Code_of_Conduct__c == null) missingFields.add('Code of Conduct');
                    if (opp.Letter_of_Credit_LC__c == null) missingFields.add('Letter of Credit (LC)');
                    if (opp.Warranty_Manual_Attachment__c == null) missingFields.add('Warranty Manual Attachment');
                    if (String.isBlank(opp.Supply_Agreement__c)) missingFields.add('Supply Agreement');
                    if (opp.Other_Product__c == null) missingFields.add('Other Product');
                    if (opp.Payment_Terms__c == null) missingFields.add('Payment Terms');
                    if (opp.PBG_Validity__c == null) missingFields.add('PBG Validity');
                    if (opp.Schema_Name__c == null) missingFields.add('Schema Name');
                    if (opp.Tender_Number__c == null) missingFields.add('Tender Number');
                    if (opp.Aging__c == null) missingFields.add('Opportunity Age (Days)');
                    if (opp.Call_Up_PO_Value__c == null) missingFields.add('Call-Up PO Value');
                    if (opp.Call_Up_PO_Reference__c == null) missingFields.add('Call-Up PO Reference');
                    if (opp.Call_Up_PO_Issued_Entity_other_than_MSA__c == null) missingFields.add('Call-Up PO Issued Entity(other than MSA)');
                    if (opp.BOM_Attachment__c == null) missingFields.add('BOM Attachment');
                    if (opp.Budget_Confirmed__c == null) missingFields.add('Budget Confirmed');
                    if (opp.Call_Up_PO_Capacity_in_MWp__c == null) missingFields.add('Call-Up PO Capacity in MWp');
                    if (opp.Call_Up_PO_Date__c == null) missingFields.add('Call-Up PO Date');
                    if (opp.Project_capacity_in_MWp_including_Spare__c == null) missingFields.add('Project capacity in MWp including Spare');
                    
                    // Additional Fields for Documentation and Technical Requirements
                    if (opp.Scope_Matrix_If_any__c==null) missingFields.add('Scope Matrix (If any)');
                    if (opp.Warranty_Manual__c == null) missingFields.add('Warranty Manual');
                    if (opp.Installation_Operation_Manual__c == null) missingFields.add('Installation & Operation Manual');
                    if (opp.Product_Data_Sheet__c == null) missingFields.add('Product Data Sheet');
                    if (opp.Additional_Technical_Requirements__c == null) missingFields.add('Additional Technical Requirements');
                    if (opp.Technical_Deviations__c == null) missingFields.add('Technical Deviations');
                    if (opp.QAP__c == null) missingFields.add('QAP');
                    if (String.isBlank(opp.Type_of_Project_Finance__c)) missingFields.add('Type of Project Finance');
                    if (opp.Payment_Terms__c == null || opp.Payment_Terms__c == 0) {
                        missingFields.add('Payment Terms');
                    }
                    if (String.isBlank(opp.Incoterms__c)) missingFields.add('Incoterms');
                    if (opp.Vehicle_Detention_Holding_Period__c == null) missingFields.add('Vehicle Detention/Holding Period');
                    if (opp.Delivery_Schedule_Timeline__c==null) missingFields.add('Delivery Schedule / Timeline');
                    if (opp.Vehicle_Detention_Holding_Charges_INR__c == null) missingFields.add('Vehicle Detention/Holding Charges (INR)');
                    if (String.isBlank(opp.Inline_Inspection__c)) missingFields.add('Inline Inspection');
                    if (String.isBlank(opp.Third_Party_Lab_Testing_if_any__c)) missingFields.add('Third-Party Lab Testing (if any)');
                    if (String.isBlank(opp.Transit_Damage_Report_Claim_Period__c)) missingFields.add('Transit Damage Report/Claim Period');
                    if (String.isBlank(opp.Delivery_Location__c)) missingFields.add('Delivery Location');
                    if (opp.Material_Dispatch_Clearance_Certificate__c==null) missingFields.add('Material Dispatch Clearance Certificate');
                    if (String.isBlank(opp.Pre_Dispatch_Inspection__c)) missingFields.add('Pre-Dispatch Inspection');
                    if (String.isBlank(opp.Vehicle_Preference_if_any__c)) missingFields.add('Vehicle Preference (if any)');
                    if (opp.Serial_Defect_Liability__c == null) missingFields.add('Serial Defect Liability');
                    if (opp.Delay_LD__c == null) missingFields.add('Delay LD');
                    if (opp.Production_Period__c == null) missingFields.add('Production Period');
                    if (opp.Third_Party_Warranty_Insurance__c == null) missingFields.add('Third-Party Warranty Insurance');
                    if (opp.Manufacturing_Warranty_in_Years__c == null) missingFields.add('Manufacturing Warranty in Years');
                    if (opp.Performance_Warranty_in_Years__c == null) missingFields.add('Performance Warranty in Years');
                    if (String.isBlank(opp.Price_Approval_Reference__c)) missingFields.add('Price Approval Reference');
                    if (String.isBlank(opp.Proposal_Reference__c)) missingFields.add('Proposal Reference');
                    if (opp.Proposal_Validity_Date__c == null) missingFields.add('Proposal Validity (Date)');
                    if (opp.Commercial_Proposal_Submission_Date__c == null) missingFields.add('Commercial Proposal Submission Date');
                    if (String.isBlank(opp.Scope_Matrix_Attachment__c)) missingFields.add('Scope Matrix Attachment');
                    if (String.isBlank(opp.BOM_Attachment__c)) missingFields.add('BOM Attachment');
                    if (String.isBlank(opp.QAP_Attachment__c)) missingFields.add('QAP Attachment');
                    if (String.isBlank(opp.Data_Sheet_Attachment__c)) missingFields.add('Data Sheet Attachment');
                    if (String.isBlank(opp.Warranty_Manual_Attachment__c)) missingFields.add('Warranty Manual Attachment');
                    if (String.isBlank(opp.Installation_Operation_Manual_Link__c)) missingFields.add('Installation & Operation Manual Link');
                    if (String.isBlank(opp.Technical_Deviations_Attachment__c)) missingFields.add('Technical Deviations Attachment');
                    if (String.isBlank(opp.Commercial_Deviations_Attachment__c)) missingFields.add('Commercial Deviations Attachment');
                    if (String.isBlank(opp.Legal_Deviations_Attachment__c)) missingFields.add('Legal Deviations Attachment');
                    if (String.isBlank(opp.Price_Approval_Sheet__c)) missingFields.add('Price Approval Sheet');
                    if (String.isBlank(opp.Contract_Pricing_Type_Fixed_Variable__c)) missingFields.add('Contract Pricing Type (Fixed / Variable)');
                    if (String.isBlank(opp.Contract_Currency_USD_INR__c)) missingFields.add('Contract Currency (USD/INR)');
                    if (opp.Exchange_Rate_INR_1_USD__c == null) missingFields.add('Exchange Rate (INR / 1 USD)');
                    if (opp.Total_Contract_Order_Value__c == null) missingFields.add('Total Contract/Order Value');
                    if (opp.Contract_Order_Date__c == null) missingFields.add('Contract/Order Date');
                    if (opp.MULTIPLE_ENTRY_PROVISION_Call_up_POs__c	 == null) missingFields.add('MULTIPLE ENTRY PROVISION (Call-up POs)');
                    if (opp.Call_Up_PO_Capacity_in_MWp__c == null) missingFields.add('Call-Up PO Capacity in MWp');
                    if (opp.Call_Up_PO_Issued_Entity_other_than_MSA__c	 == null) missingFields.add('Call-Up PO Issued Entity (other than MSA)');
                    if (opp.Tentative_Production_Start_Date__c == null) missingFields.add('Tentative Production Start Date');
                    if (String.isBlank(opp.Purchase_Order_Contract_Reference__c)) missingFields.add('Purchase Order/Contract Reference');
                    if (String.isBlank(opp.Purchase_Order_Contract_Attachment__c)) missingFields.add('Purchase Order/Contract Attachment');
                    if (opp.Billing_Address_with_GST__c == null) missingFields.add('Billing Address with GST');
                    if (opp.Shipping_Address_with_GST__c == null) missingFields.add('Shipping Address with GST');
                    if (String.isBlank(opp.Production_Plan_Attachment__c)) missingFields.add('Production Plan Attachment');
                    if (opp.ABG_Issuance_Date__c == null) missingFields.add('ABG Issuance Date');
                    if (opp.ABG__c == null) missingFields.add('ABG');
                    if (opp.Advance_Payment__c == null) missingFields.add('Advance Payment');
                    if (opp.PBG_Expiry_Date__c == null) missingFields.add('PBG Expiry Date');
                    if (opp.PBG_Value__c == null) missingFields.add('PBG Value');
                    if (opp.PDC__c == null) missingFields.add('PDC');
                    if (opp.PDC_Expiry_Date__c == null) missingFields.add('PDC Expiry Date');
                    if (opp.PDC_Value__c == null) missingFields.add('PDC Value');
                    if (opp.Letter_of_Credit_LC__c == null) missingFields.add('Letter of Credit (LC)');
                    if (opp.LC_Clause_46A_Set_of_Documents__c==null) missingFields.add('LC Clause- 46A (Set of Documents)');
                    if (opp.LC_Usance_Interest_Cost_Buyer_Seller__c == null) missingFields.add('LC Usance Interest Cost (Buyer/Seller)');
                    if (opp.Finance_Review_Clearance_of_LC__c == null) missingFields.add('Finance Review/ Clearance of LC');
                    if (opp.LC_Usance_Period_in_Days__c == null) missingFields.add('LC Usance Period in Days');
                    if (opp.Final_LC_Attachment__c == null) missingFields.add('Final LC & Attachment');
                    
                    // Show errors if any fields are missing
                    if (!missingFields.isEmpty()) {
                        opp.addError(
                            'The following fields are required when Stage is "Contract Agreement":\n\n' +
                            '• ' + String.join(missingFields, '\n• ')
                        );
                    }
                }
        }
    }
}