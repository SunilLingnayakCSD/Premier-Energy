public class OpportunityClosedWonValidation {
    
    public static void validate(List<Opportunity> newList, Map<Id, Opportunity> oldMap) {
        
        Set<Id> recordTypeIds = new Set<Id>();
        for (Opportunity opp : newList) {
            if (opp.RecordTypeId != null) {
                recordTypeIds.add(opp.RecordTypeId);
            }
        }
        
        Map<Id, RecordType> recordTypeMap = new Map<Id, RecordType>(
            [SELECT Id, DeveloperName FROM RecordType WHERE SObjectType = 'Opportunity' AND Id IN :recordTypeIds]);
        
        for (Opportunity opp : newList) {
            Opportunity oldOpp = (oldMap != null) ? oldMap.get(opp.Id) : null;
            RecordType rt = recordTypeMap.get(opp.RecordTypeId);
            
            // Call method to check missing required fields
            validateMissingFields(opp, oldOpp, rt);
            
            // Call method to prevent edits after approval
            validateRestrictedFieldEdits(opp, oldOpp, rt);
        }
    }
    
    public static void validateMissingFields(Opportunity opp, Opportunity oldOpp, RecordType rt) {
        if (rt != null && rt.DeveloperName == 'Key_Account_Private' && opp.StageName != null && 
            (opp.StageName.contains('Price Approval') || opp.StageName.contains('Proposal Submission')) && 
            (oldOpp == null || oldOpp.StageName == null || !(oldOpp.StageName.contains('Price Approval') || oldOpp.StageName.contains('Proposal Submission')))) {
                
                List<String> missingFields = new List<String>();
                
                if (String.isBlank(opp.Transaction_Modality__c)) missingFields.add('Transaction Modality');
                if (String.isBlank(opp.Type_of_Project_Finance1__c)) missingFields.add('Type of Project Finance');
                if (opp.Payment_Terms__c == null) missingFields.add('Payment Terms');
                if (opp.Delivery_Schedule_Timeline__c == null) missingFields.add('Delivery Schedule / Timeline');
                if (opp.Production_Period__c == null) missingFields.add('Production Period');
                if (opp.Delay_LD1__c == null) missingFields.add('Delay LD');
                if (String.isBlank(opp.Pre_Dispatch_Inspection__c)) missingFields.add('Pre-Dispatch Inspection');
                if (String.isBlank(opp.Third_Party_Lab_Testing_if_any__c)) missingFields.add('Third-Party Lab Testing (if any)');
                if (opp.Material_Dispatch_Clearance_Certificate__c == null) missingFields.add('Material Dispatch Clearance Certificate');
                if (String.isBlank(opp.Delivery_Location__c)) missingFields.add('Delivery Location');
                if (String.isBlank(opp.Inline_Inspection__c)) missingFields.add('Inline Inspection');
                if (String.isBlank(opp.Incoterms__c)) missingFields.add('Incoterms');
                if (String.isBlank(opp.Vehicle_Preference_if_any1__c)) missingFields.add('Vehicle Preference (if any)');
                if (opp.Serial_Defect_Liability__c == null) missingFields.add('Serial Defect Liability');
                if (String.isBlank(opp.Transit_Insurance_by__c)) missingFields.add('Transit Insurance by');
                if (opp.Vehicle_Detention_Holding_Period_Hrs__c == null) missingFields.add('Vehicle Detention/Holding Period');
                if (String.isBlank(opp.Transit_Damage_Report_Claim_Period_Days__c)) missingFields.add('Transit Damage Report/Claim Period');
                if (opp.Third_Party_Warranty_Insurance__c == null) missingFields.add('Third-Party Warranty Insurance');
                if (opp.Warranty_Terms__c == null) missingFields.add('Warranty Terms');
                if (opp.Module_Degradation_FirstYear__c == null) missingFields.add('Module Degradation%(First Year)');
                if (opp.Module_DegradationYoY__c == null) missingFields.add('Module Degradation%(YoY)');
                if (opp.Vehicle_Detention_Holding_Charges_INR__c == null) missingFields.add('Vehicle Detention/Holding Charges (INR)');
                if (opp.Delay_in_Repair_or_Replacement_Terms__c == null) missingFields.add('Delay in Repair or Replacement - Terms');
                if (opp.Commercial_Proposal_Submission_Date__c == null) missingFields.add('Commercial Proposal Submission Date');
                if (opp.Project_capacity_in_MWp_including_Spare__c == null) missingFields.add('Project capacity in MWp including Spare');
                if (String.isBlank(opp.Wattage_Wp_Cell_Module1__c)) missingFields.add('Wattage Wp (Cell/ Module)');
                if (opp.Delivery_Schedule_Timeline__c == null) missingFields.add('Delivery Schedule / Timeline');
                if (String.isBlank(opp.Delivery_Location__c)) missingFields.add('Delivery Location');
                if (String.isBlank(opp.Ship_to__c)) missingFields.add('Ship to');
                if (String.isBlank(opp.Premier_Business_Entity1__c)) missingFields.add('Premier Business Entity');
                if (opp.RFID_Readers_Qty__c == null) missingFields.add('RFID Readers (Qty)');
                if (opp.Payment_Terms__c == null) missingFields.add('Payment Term Advance(%)');
                if (String.isBlank(opp.LC_Usance_Period_in_Days__c)) missingFields.add('LC Usance Period in Days');
                if (opp.ABG_Issuance_Date__c == null) missingFields.add('ABG Issuance Date');
                if (opp.ABG_Expiry_Date__c == null) missingFields.add('ABG Expiry Date');
                if (opp.ABG_Validity_Days__c == null) missingFields.add('ABG Validity');
                if (opp.PBG_Issuance_Date__c == null) missingFields.add('PBG Issuance Date');
                if (opp.PBG_Expiry_Date__c == null) missingFields.add('PBG Expiry Date');
                if (opp.PBG_Validity_Days__c == null) missingFields.add('PBG Validity');
                if (String.isBlank(opp.Domestic_Exports__c)) missingFields.add('Domestic/ Exports');
                if (String.isBlank(opp.Segment1__c)) missingFields.add('Segment');
                if (String.isBlank(opp.DCR_Non_DCR1__c)) missingFields.add('DCR/ Non-DCR');
                if (String.isBlank(opp.Product_Details_Technology_Type1__c)) missingFields.add('Product Details');
                if (opp.Project_capacity_in_MWp_including_Spare__c == null) missingFields.add('Project Capacity in MWp including Spare');
                if (opp.Incoterms__c == null) missingFields.add('Incoterms');
                if (String.isBlank(opp.Third_Party_Warranty_Insurance__c)) missingFields.add('Third-Party Warranty Insurance');
                if (String.isBlank(opp.Payment_Term_Balance__c)) missingFields.add('Payment Term (Balance)');
                if (opp.Vehicle_Detention_Holding_Charges_INR__c == null) missingFields.add('Vehicle Detention/Holding Charges (INR)');
                if (opp.Delay_in_Repair_or_Replacement_Terms__c == null) missingFields.add('Delay in Repair or Replacement - Terms');
                if (opp.Commercial_Deviations__c == null) missingFields.add('Commercial Deviation');
                
                if (!missingFields.isEmpty()) {
                    opp.addError(
                        'The following fields are required:\n\n' +
                        '• ' + String.join(missingFields, '\n• ')
                    );
                }
            }
    }
    
    public static void validateRestrictedFieldEdits(Opportunity opp, Opportunity oldOpp, RecordType rt) {
        if (rt != null &&
            (opp.StageName != null && (opp.StageName.contains('Price Approval') || opp.StageName.contains('Proposal Submission'))) &&
            (opp.National_Head_Approval__c == 'Sent for Approval') &&
            oldOpp != null
           ){
               List<String> restrictedFieldsChanged = new List<String>();
               
               if (opp.Incolocation__c != oldOpp.Incolocation__c)
                    restrictedFieldsChanged.add('Incolocation');
                
                if (opp.Ship_To_Customer_Code__c != oldOpp.Ship_To_Customer_Code__c)
                    restrictedFieldsChanged.add('Ship To Customer Code');
                
                if (opp.BillToCustomerCode__c != oldOpp.BillToCustomerCode__c)
                    restrictedFieldsChanged.add('Bill To Customer Code');
                
                if (opp.Ship_to__c != oldOpp.Ship_to__c)
                    restrictedFieldsChanged.add('Ship To');
                
                if (opp.Bill_to__c != oldOpp.Bill_to__c)
                    restrictedFieldsChanged.add('Bill To');
               
               if (!restrictedFieldsChanged.isEmpty()) {
                   opp.addError(
                       'Address section is locked after sending for approval.\n\n' +
                       '• ' + String.join(restrictedFieldsChanged, '\n• ')
                   );
               }
      }
        if (rt != null &&
            (opp.StageName != null && (opp.StageName.contains('Price Approval') || opp.StageName.contains('Proposal Submission'))) &&
            (opp.National_Head_Approval__c == 'Approved' || opp.MD_Approval__c == 'Approved') &&
            oldOpp != null
           ) {
               List<String> restrictedFieldsChanged = new List<String>();
               
               if (opp.Product_Category1__c != oldOpp.Product_Category1__c)
                   restrictedFieldsChanged.add('Product Category');
               
               //if (opp.Probability != oldOpp.Probability)
                   //restrictedFieldsChanged.add('Probability');
               
               if (opp.Plant__c != oldOpp.Plant__c)
                   restrictedFieldsChanged.add('Plant');
               if (opp.Name != oldOpp.Name) restrictedFieldsChanged.add('Name');
               if (opp.Id__c != oldOpp.Id__c) restrictedFieldsChanged.add('Id');
               if (opp.AccountId != oldOpp.AccountId) restrictedFieldsChanged.add('Account');
               if (opp.Segment1__c != oldOpp.Segment1__c) restrictedFieldsChanged.add('Segment');
               if (opp.Other_Segment__c != oldOpp.Other_Segment__c) restrictedFieldsChanged.add('Other Segment');
               if (opp.Domestic_Exports__c != oldOpp.Domestic_Exports__c) restrictedFieldsChanged.add('Domestic/Exports');
               if (opp.Order_Type2__c != oldOpp.Order_Type2__c) restrictedFieldsChanged.add('Order Type 2');
               if (opp.DCR_Non_DCR1__c != oldOpp.DCR_Non_DCR1__c) restrictedFieldsChanged.add('DCR/Non-DCR');
               if (opp.Product_Type__c != oldOpp.Product_Type__c) restrictedFieldsChanged.add('Product Type');
               if (opp.Other_Product__c != oldOpp.Other_Product__c) restrictedFieldsChanged.add('Other Product');
               if (opp.Project_COD__c != oldOpp.Project_COD__c) restrictedFieldsChanged.add('Project COD');
               if (opp.Customer_SPOC_Name__c != oldOpp.Customer_SPOC_Name__c) restrictedFieldsChanged.add('Customer SPOC Name');
               if (opp.Customer_SPOC_Mobile_No__c != oldOpp.Customer_SPOC_Mobile_No__c) restrictedFieldsChanged.add('Customer SPOC Mobile No');
               if (opp.Financial_Due_diligence_if_any__c != oldOpp.Financial_Due_diligence_if_any__c) restrictedFieldsChanged.add('Financial Due Diligence (if any)');
               if (opp.Financial_Due_diligence_Remarks__c != oldOpp.Financial_Due_diligence_Remarks__c) restrictedFieldsChanged.add('Financial Due Diligence Remarks');
               if (opp.Tender_Requirements_if_any__c != oldOpp.Tender_Requirements_if_any__c) restrictedFieldsChanged.add('Tender Requirements (if any)');
               if (opp.Tender_Requirement_Remarks__c != oldOpp.Tender_Requirement_Remarks__c) restrictedFieldsChanged.add('Tender Requirement Remarks');
               if (opp.Contract_Closure_by__c != oldOpp.Contract_Closure_by__c) restrictedFieldsChanged.add('Contract Closure by');
               if (opp.Delivery_Required_by__c != oldOpp.Delivery_Required_by__c) restrictedFieldsChanged.add('Delivery Required by');
               if (opp.Distribution_Channel1__c != oldOpp.Distribution_Channel1__c) restrictedFieldsChanged.add('Distribution Channel');
               if (opp.Cable_length__c != oldOpp.Cable_length__c) restrictedFieldsChanged.add('Cable Length');
               if (opp.CloseDate != oldOpp.CloseDate) restrictedFieldsChanged.add('Close Date');
               if (opp.Other_Details_Note__c != oldOpp.Other_Details_Note__c) restrictedFieldsChanged.add('Other Details/Note');
               if (opp.LC_reference__c != oldOpp.LC_reference__c) restrictedFieldsChanged.add('LC Reference');
               if (opp.Shipping_Point__c != oldOpp.Shipping_Point__c) restrictedFieldsChanged.add('Shipping Point');
               if (opp.Sales_Org1__c != oldOpp.Sales_Org1__c) restrictedFieldsChanged.add('Sales Org');
               if (opp.Customer_Type__c != oldOpp.Customer_Type__c) restrictedFieldsChanged.add('Customer Type');
               //if (opp.Probability != oldOpp.Probability) restrictedFieldsChanged.add('Probability');
               if (opp.Win_Probability_del__c != oldOpp.Win_Probability_del__c) restrictedFieldsChanged.add('Win Probability (del)');
               if (opp.Win_Probability__c != oldOpp.Win_Probability__c) restrictedFieldsChanged.add('Win Probability');
               //if (opp.StageName != oldOpp.StageName) restrictedFieldsChanged.add('Stage');
               if (opp.Customer_Registered_Address__c != oldOpp.Customer_Registered_Address__c) restrictedFieldsChanged.add('Customer Registered Address');
               if (opp.Customer_Role__c != oldOpp.Customer_Role__c) restrictedFieldsChanged.add('Customer Role');
               if (opp.Other_Customer_Role__c != oldOpp.Other_Customer_Role__c) restrictedFieldsChanged.add('Other Customer Role');
               if (opp.End_Customer_Name_if_any__c != oldOpp.End_Customer_Name_if_any__c) restrictedFieldsChanged.add('End Customer Name (if any)');
               if (opp.Project_capacity_in_MWp_including_Spare__c != oldOpp.Project_capacity_in_MWp_including_Spare__c) restrictedFieldsChanged.add('Project Capacity in MWp including Spare');
               if (opp.Product_Details_Technology_Type1__c != oldOpp.Product_Details_Technology_Type1__c) restrictedFieldsChanged.add('Product Details');
               if (opp.Other_Product_Details__c != oldOpp.Other_Product_Details__c) restrictedFieldsChanged.add('Other Product Details');
               if (opp.Premier_Business_Entity1__c != oldOpp.Premier_Business_Entity1__c) restrictedFieldsChanged.add('Premier Business Entity');
               if (opp.Wattage_Wp_Cell_Module1__c != oldOpp.Wattage_Wp_Cell_Module1__c) restrictedFieldsChanged.add('Wattage Wp (Cell/Module)');
               //if (opp.Plant__c != oldOpp.Plant__c) restrictedFieldsChanged.add('Plant');
               if (opp.Customer_SPOC_EMAIL__c != oldOpp.Customer_SPOC_EMAIL__c) restrictedFieldsChanged.add('Customer SPOC Email');
               if (opp.Technical_Due_diligence_if_any__c != oldOpp.Technical_Due_diligence_if_any__c) restrictedFieldsChanged.add('Technical Due Diligence (if any)');
               if (opp.Technical_due_diligence_Remarks__c != oldOpp.Technical_due_diligence_Remarks__c) restrictedFieldsChanged.add('Technical Due Diligence Remarks');
               if (opp.Audit_Requirements_if_any__c != oldOpp.Audit_Requirements_if_any__c) restrictedFieldsChanged.add('Audit Requirements (if any)');
               if (opp.Audit_Rquirements_Remarks__c != oldOpp.Audit_Rquirements_Remarks__c) restrictedFieldsChanged.add('Audit Requirements Remarks');
               if (opp.Delivery_To_Date__c != oldOpp.Delivery_To_Date__c) restrictedFieldsChanged.add('Delivery To Date');
               if (opp.Order_Type__c != oldOpp.Order_Type__c) restrictedFieldsChanged.add('Order Type');
               if (opp.Tentative_Order_Value__c != oldOpp.Tentative_Order_Value__c) restrictedFieldsChanged.add('Tentative Order Value');
               if (opp.List_of_Pipeline_Projects__c != oldOpp.List_of_Pipeline_Projects__c) restrictedFieldsChanged.add('List of Pipeline Projects');
               if (opp.Pipeline_Projects_Capacity_in_MWp__c != oldOpp.Pipeline_Projects_Capacity_in_MWp__c) restrictedFieldsChanged.add('Pipeline Projects Capacity in MWp');
               if (opp.freight_cost__c != oldOpp.freight_cost__c) restrictedFieldsChanged.add('Freight Cost');
               if (opp.Region__c != oldOpp.Region__c) restrictedFieldsChanged.add('Region');
               if (opp.Legal_Review_Clearance__c != oldOpp.Legal_Review_Clearance__c) restrictedFieldsChanged.add('Legal Review Clearance');
               if(opp.Scope_Matrix_If_any__c != oldOpp.Scope_Matrix_If_any__c) restrictedFieldsChanged.add('Scope matrix');
               if(opp.Product_Data_Sheet__c != oldOpp.Product_Data_Sheet__c) restrictedFieldsChanged.add('product data sheet');
               if(opp.Warranty_Manual__c != oldOpp.Warranty_Manual__c) restrictedFieldsChanged.add('warranty manual');
               if(opp.Additional_Technical_Requirements1__c != oldOpp.Additional_Technical_Requirements1__c) restrictedFieldsChanged.add('Additional technical requirements');
               if(opp.ReasonAdditional_Technical_Requirements1__c != oldOpp.ReasonAdditional_Technical_Requirements1__c) restrictedFieldsChanged.add('Reason additional technical requirements');
               if(opp.BOM1__c != oldOpp.BOM1__c) restrictedFieldsChanged.add(' BOM1');
               if(opp.QAP__c != oldOpp.QAP__c) restrictedFieldsChanged.add('QAP');
               if(opp.Installation_Operation_Manual__c != oldOpp.Installation_Operation_Manual__c) restrictedFieldsChanged.add('Installation opertation manual');
               if(opp.Technical_Deviations__c != oldOpp.Technical_Deviations__c) restrictedFieldsChanged.add('technical deviation');
               if(opp.Transaction_Modality__c != oldOpp.Transaction_Modality__c) restrictedFieldsChanged.add('Transcation Modality');
               if(opp.Other_Transaction_Modality__c != oldOpp.Other_Transaction_Modality__c) restrictedFieldsChanged.add('Other Transcation Modality');
               if(opp.Payment_Terms1__c != oldOpp.Payment_Terms1__c) restrictedFieldsChanged.add('Payment Terms');
               if(opp.Other_Payment_Terms__c != oldOpp.Other_Payment_Terms__c) restrictedFieldsChanged.add('Other Payment Terms');
               if(opp.Payment_Term_Balance__c != oldOpp.Payment_Term_Balance__c) restrictedFieldsChanged.add('Payment Term Balance');
               if(opp.Payment_Terms__c != oldOpp.Payment_Terms__c) restrictedFieldsChanged.add('Payment Terms');
               if(opp.Other_Reason_for_Payment_Terms__c != oldOpp.Other_Reason_for_Payment_Terms__c) restrictedFieldsChanged.add('Other Reason For Payment Terms');
               if(opp.Production_Period__c != oldOpp.Production_Period__c) restrictedFieldsChanged.add('Production Period');
               if(opp.Inline_Inspection__c != oldOpp.Inline_Inspection__c) restrictedFieldsChanged.add('Inline Inspection');
               if(opp.Third_Party_Lab_Testing_if_any__c != oldOpp.Third_Party_Lab_Testing_if_any__c) restrictedFieldsChanged.add('Third Party Lab Testing If Any');
               if(opp.Incoterms__c != oldOpp.Incoterms__c) restrictedFieldsChanged.add('Incoterms');
               if(opp.Vehicle_Preference_if_any1__c != oldOpp.Vehicle_Preference_if_any1__c) restrictedFieldsChanged.add('Vehicle Prefernce If Any');
               if(opp.PalletBasedOnVehicle__c != oldOpp.PalletBasedOnVehicle__c) restrictedFieldsChanged.add('Pallet Based on Vehicle');
               if(opp.Other_Vehicle_Preference_if_any__c != oldOpp.Other_Vehicle_Preference_if_any__c) restrictedFieldsChanged.add('Other Vehicle Preference if any');
               if(opp.Vehicle_Detention_Holding_Period_Hrs__c != oldOpp.Vehicle_Detention_Holding_Period_Hrs__c) restrictedFieldsChanged.add('Vehicle Detention Holding Period Hrs');
               if(opp.Transit_Damage_Report_Claim_Period_Days__c != oldOpp.Transit_Damage_Report_Claim_Period_Days__c) restrictedFieldsChanged.add('Transit Damage Report Claim Period Days');
               if(opp.Serial_Defect_Liability__c != oldOpp.Serial_Defect_Liability__c) restrictedFieldsChanged.add('Serial Defect Liability');
               if(opp.Warranty_Terms__c != oldOpp.Warranty_Terms__c) restrictedFieldsChanged.add('Warranty Terms');
               if(opp.Other_Warranty_Terms__c != oldOpp.Other_Warranty_Terms__c) restrictedFieldsChanged.add('Other Warranty Terms');
               if(opp.Type_of_Project_Finance1__c != oldOpp.Type_of_Project_Finance1__c) restrictedFieldsChanged.add('Type of Project Finance');
               if(opp.Other_Type_of_Project_Finance__c != oldOpp.Other_Type_of_Project_Finance__c) restrictedFieldsChanged.add('Other Type of Project Finance');
               if(opp.Delivery_Schedule_Timeline__c != oldOpp.Delivery_Schedule_Timeline__c) restrictedFieldsChanged.add('Delivery Schedule Timeline');
               if(opp.Delay_LD1__c != oldOpp.Delay_LD1__c) restrictedFieldsChanged.add('Delay LD');
               if(opp.Other_Reason_for_Delay_LD__c != oldOpp.Other_Reason_for_Delay_LD__c) restrictedFieldsChanged.add('Other Reason for Delay LD');
               if(opp.Pre_Dispatch_Inspection__c != oldOpp.Pre_Dispatch_Inspection__c) restrictedFieldsChanged.add('Pre Dispatch Inspection');
               if(opp.Material_Dispatch_Clearance_Certificate__c != oldOpp.Material_Dispatch_Clearance_Certificate__c) restrictedFieldsChanged.add('Material Dispatch Clearance Certificate');
               if(opp.Delivery_Location__c != oldOpp.Delivery_Location__c) restrictedFieldsChanged.add('Delivery Location');
               if(opp.Transit_Insurance_by__c != oldOpp.Transit_Insurance_by__c) restrictedFieldsChanged.add('Transit Insurance by');
               if(opp.Vehicle_Detention_Holding_Charges_INR__c != oldOpp.Vehicle_Detention_Holding_Charges_INR__c) restrictedFieldsChanged.add('Vehicle Detention Holding Charges INR');
               if(opp.Third_Party_Warranty_Insurance__c != oldOpp.Third_Party_Warranty_Insurance__c) restrictedFieldsChanged.add('Third Party Warranty Insurance');
               if(opp.RFID_Readers_Qty__c != oldOpp.RFID_Readers_Qty__c) restrictedFieldsChanged.add('RFID Readers Qty');
               if(opp.Module_Degradation_FirstYear__c != oldOpp.Module_Degradation_FirstYear__c) restrictedFieldsChanged.add('Module Degradation FirstYear');
               if(opp.Other_Reason_for_Module_Degradation__c != oldOpp.Other_Reason_for_Module_Degradation__c) restrictedFieldsChanged.add('Other Reason for Module Degradation');
               if(opp.Delay_in_Repair_or_Replacement_Terms__c != oldOpp.Delay_in_Repair_or_Replacement_Terms__c) restrictedFieldsChanged.add('Delay in Repair or Replacement Terms');
               if(opp.Commercial_Deviations__c != oldOpp.Commercial_Deviations__c) restrictedFieldsChanged.add('Commercial Deviations');
               if(opp.Module_DegradationYoY__c != oldOpp.Module_DegradationYoY__c) restrictedFieldsChanged.add('Module Degradation YoY');
               if(opp.Other_Module_Degradation_YoY__c != oldOpp.Other_Module_Degradation_YoY__c) restrictedFieldsChanged.add('Other Module Degradation YoY');
               if(opp.Code_of_Conduct__c != oldOpp.Code_of_Conduct__c) restrictedFieldsChanged.add('Code of Conduct');
               if(opp.Change_in_Law_Taxes_Codes_Standards__c != oldOpp.Change_in_Law_Taxes_Codes_Standards__c)
                   restrictedFieldsChanged.add('Change in Law Taxes Codes Standards');
               
               if(opp.Default_Notice__c != oldOpp.Default_Notice__c)
                   restrictedFieldsChanged.add('Default Notice');
               
               if(opp.Dispute_Resolution__c != oldOpp.Dispute_Resolution__c)
                   restrictedFieldsChanged.add('Dispute Resolution');
               
               if(opp.Force_Majeure__c != oldOpp.Force_Majeure__c)
                   restrictedFieldsChanged.add('Force Majeure');
               
               if(opp.Limitation_of_Liability__c != oldOpp.Limitation_of_Liability__c)
                   restrictedFieldsChanged.add('Limitation of Liability');
               
               if(opp.Anti_Bribery_Corruption__c != oldOpp.Anti_Bribery_Corruption__c)
                   restrictedFieldsChanged.add('Anti Bribery Corruption');
               
               if(opp.Change_in_Law_Taxes_scope_during_execu__c != oldOpp.Change_in_Law_Taxes_scope_during_execu__c)
                   restrictedFieldsChanged.add('Change in Law Taxes scope during execution');
               
               if(opp.Governing_Laws_Jurisdiction_and_Arbitra__c != oldOpp.Governing_Laws_Jurisdiction_and_Arbitra__c)
                   restrictedFieldsChanged.add('Governing Laws Jurisdiction and Arbitration');
               
               if(opp.Customer_Audit_Rights__c != oldOpp.Customer_Audit_Rights__c)
                   restrictedFieldsChanged.add('Customer Audit Rights');
               
               if(opp.Termination__c != oldOpp.Termination__c)
                   restrictedFieldsChanged.add('Termination');
               
               if(opp.Legal_Deviations__c != oldOpp.Legal_Deviations__c)
                   restrictedFieldsChanged.add('Legal Deviations');
               
               if (opp.Incolocation__c != oldOpp.Incolocation__c)
                    restrictedFieldsChanged.add('Incolocation');
                
                if (opp.Ship_To_Customer_Code__c != oldOpp.Ship_To_Customer_Code__c)
                    restrictedFieldsChanged.add('Ship To Customer Code');
                
                if (opp.BillToCustomerCode__c != oldOpp.BillToCustomerCode__c)
                    restrictedFieldsChanged.add('Bill To Customer Code');
                
                if (opp.Ship_to__c != oldOpp.Ship_to__c)
                    restrictedFieldsChanged.add('Ship To');
                
                if (opp.Bill_to__c != oldOpp.Bill_to__c)
                    restrictedFieldsChanged.add('Bill To');
               
               
               // Add any additional restricted fields here...
               
               if (!restrictedFieldsChanged.isEmpty()) {
                   opp.addError(
                       'You cannot modify the following fields after approval by National Head or MD:\n\n' +
                       '• ' + String.join(restrictedFieldsChanged, '\n• ')
                   );
               }
           }
            if (
                rt != null &&
                (opp.StageName != null && (opp.StageName.contains('Contract Agreement'))) &&
                (opp.National_Head_Approval__c == 'Approved' || opp.MD_Approval__c == 'Approved') &&
                oldOpp != null
                    ){
                List<String> restrictedFieldsChanged = new List<String>();
               
               if (opp.Product_Category1__c != oldOpp.Product_Category1__c)
                   restrictedFieldsChanged.add('Product Category');
               
               //if (opp.Probability != oldOpp.Probability)
                   //restrictedFieldsChanged.add('Probability');
               
               if (opp.Plant__c != oldOpp.Plant__c)
                   restrictedFieldsChanged.add('Plant');
               if (opp.Name != oldOpp.Name) restrictedFieldsChanged.add('Name');
               if (opp.Id__c != oldOpp.Id__c) restrictedFieldsChanged.add('Id');
               if (opp.AccountId != oldOpp.AccountId) restrictedFieldsChanged.add('Account');
               if (opp.Segment1__c != oldOpp.Segment1__c) restrictedFieldsChanged.add('Segment');
               if (opp.Other_Segment__c != oldOpp.Other_Segment__c) restrictedFieldsChanged.add('Other Segment');
               if (opp.Domestic_Exports__c != oldOpp.Domestic_Exports__c) restrictedFieldsChanged.add('Domestic/Exports');
               if (opp.Order_Type2__c != oldOpp.Order_Type2__c) restrictedFieldsChanged.add('Order Type 2');
               if (opp.DCR_Non_DCR1__c != oldOpp.DCR_Non_DCR1__c) restrictedFieldsChanged.add('DCR/Non-DCR');
               if (opp.Product_Type__c != oldOpp.Product_Type__c) restrictedFieldsChanged.add('Product Type');
               if (opp.Other_Product__c != oldOpp.Other_Product__c) restrictedFieldsChanged.add('Other Product');
               if (opp.Project_COD__c != oldOpp.Project_COD__c) restrictedFieldsChanged.add('Project COD');
               if (opp.Customer_SPOC_Name__c != oldOpp.Customer_SPOC_Name__c) restrictedFieldsChanged.add('Customer SPOC Name');
               if (opp.Customer_SPOC_Mobile_No__c != oldOpp.Customer_SPOC_Mobile_No__c) restrictedFieldsChanged.add('Customer SPOC Mobile No');
               if (opp.Financial_Due_diligence_if_any__c != oldOpp.Financial_Due_diligence_if_any__c) restrictedFieldsChanged.add('Financial Due Diligence (if any)');
               if (opp.Financial_Due_diligence_Remarks__c != oldOpp.Financial_Due_diligence_Remarks__c) restrictedFieldsChanged.add('Financial Due Diligence Remarks');
               if (opp.Tender_Requirements_if_any__c != oldOpp.Tender_Requirements_if_any__c) restrictedFieldsChanged.add('Tender Requirements (if any)');
               if (opp.Tender_Requirement_Remarks__c != oldOpp.Tender_Requirement_Remarks__c) restrictedFieldsChanged.add('Tender Requirement Remarks');
               if (opp.Contract_Closure_by__c != oldOpp.Contract_Closure_by__c) restrictedFieldsChanged.add('Contract Closure by');
               if (opp.Delivery_Required_by__c != oldOpp.Delivery_Required_by__c) restrictedFieldsChanged.add('Delivery Required by');
               if (opp.Distribution_Channel1__c != oldOpp.Distribution_Channel1__c) restrictedFieldsChanged.add('Distribution Channel');
               if (opp.Cable_length__c != oldOpp.Cable_length__c) restrictedFieldsChanged.add('Cable Length');
               if (opp.CloseDate != oldOpp.CloseDate) restrictedFieldsChanged.add('Close Date');
               if (opp.Other_Details_Note__c != oldOpp.Other_Details_Note__c) restrictedFieldsChanged.add('Other Details/Note');
               if (opp.LC_reference__c != oldOpp.LC_reference__c) restrictedFieldsChanged.add('LC Reference');
               if (opp.Shipping_Point__c != oldOpp.Shipping_Point__c) restrictedFieldsChanged.add('Shipping Point');
               if (opp.Sales_Org1__c != oldOpp.Sales_Org1__c) restrictedFieldsChanged.add('Sales Org');
               if (opp.Customer_Type__c != oldOpp.Customer_Type__c) restrictedFieldsChanged.add('Customer Type');
              // if (opp.Probability != oldOpp.Probability) restrictedFieldsChanged.add('Probability');
               if (opp.Win_Probability_del__c != oldOpp.Win_Probability_del__c) restrictedFieldsChanged.add('Win Probability (del)');
               if (opp.Win_Probability__c != oldOpp.Win_Probability__c) restrictedFieldsChanged.add('Win Probability');
               //if (opp.StageName != oldOpp.StageName) restrictedFieldsChanged.add('Stage');
               if (opp.Customer_Registered_Address__c != oldOpp.Customer_Registered_Address__c) restrictedFieldsChanged.add('Customer Registered Address');
               if (opp.Customer_Role__c != oldOpp.Customer_Role__c) restrictedFieldsChanged.add('Customer Role');
               if (opp.Other_Customer_Role__c != oldOpp.Other_Customer_Role__c) restrictedFieldsChanged.add('Other Customer Role');
               if (opp.End_Customer_Name_if_any__c != oldOpp.End_Customer_Name_if_any__c) restrictedFieldsChanged.add('End Customer Name (if any)');
               if (opp.Project_capacity_in_MWp_including_Spare__c != oldOpp.Project_capacity_in_MWp_including_Spare__c) restrictedFieldsChanged.add('Project Capacity in MWp including Spare');
               if (opp.Product_Details_Technology_Type1__c != oldOpp.Product_Details_Technology_Type1__c) restrictedFieldsChanged.add('Product Details');
               if (opp.Other_Product_Details__c != oldOpp.Other_Product_Details__c) restrictedFieldsChanged.add('Other Product Details');
               if (opp.Premier_Business_Entity1__c != oldOpp.Premier_Business_Entity1__c) restrictedFieldsChanged.add('Premier Business Entity');
               if (opp.Wattage_Wp_Cell_Module1__c != oldOpp.Wattage_Wp_Cell_Module1__c) restrictedFieldsChanged.add('Wattage Wp (Cell/Module)');
               //if (opp.Plant__c != oldOpp.Plant__c) restrictedFieldsChanged.add('Plant');
               if (opp.Customer_SPOC_EMAIL__c != oldOpp.Customer_SPOC_EMAIL__c) restrictedFieldsChanged.add('Customer SPOC Email');
               if (opp.Technical_Due_diligence_if_any__c != oldOpp.Technical_Due_diligence_if_any__c) restrictedFieldsChanged.add('Technical Due Diligence (if any)');
               if (opp.Technical_due_diligence_Remarks__c != oldOpp.Technical_due_diligence_Remarks__c) restrictedFieldsChanged.add('Technical Due Diligence Remarks');
               if (opp.Audit_Requirements_if_any__c != oldOpp.Audit_Requirements_if_any__c) restrictedFieldsChanged.add('Audit Requirements (if any)');
               if (opp.Audit_Rquirements_Remarks__c != oldOpp.Audit_Rquirements_Remarks__c) restrictedFieldsChanged.add('Audit Requirements Remarks');
               if (opp.Delivery_To_Date__c != oldOpp.Delivery_To_Date__c) restrictedFieldsChanged.add('Delivery To Date');
               if (opp.Order_Type__c != oldOpp.Order_Type__c) restrictedFieldsChanged.add('Order Type');
               if (opp.Tentative_Order_Value__c != oldOpp.Tentative_Order_Value__c) restrictedFieldsChanged.add('Tentative Order Value');
               if (opp.List_of_Pipeline_Projects__c != oldOpp.List_of_Pipeline_Projects__c) restrictedFieldsChanged.add('List of Pipeline Projects');
               if (opp.Pipeline_Projects_Capacity_in_MWp__c != oldOpp.Pipeline_Projects_Capacity_in_MWp__c) restrictedFieldsChanged.add('Pipeline Projects Capacity in MWp');
               if (opp.freight_cost__c != oldOpp.freight_cost__c) restrictedFieldsChanged.add('Freight Cost');
               if (opp.Region__c != oldOpp.Region__c) restrictedFieldsChanged.add('Region');
               if (opp.Legal_Review_Clearance__c != oldOpp.Legal_Review_Clearance__c) restrictedFieldsChanged.add('Legal Review Clearance');
               if(opp.Scope_Matrix_If_any__c != oldOpp.Scope_Matrix_If_any__c) restrictedFieldsChanged.add('Scope matrix');
               if(opp.Product_Data_Sheet__c != oldOpp.Product_Data_Sheet__c) restrictedFieldsChanged.add('product data sheet');
               if(opp.Warranty_Manual__c != oldOpp.Warranty_Manual__c) restrictedFieldsChanged.add('warranty manual');
               if(opp.Additional_Technical_Requirements1__c != oldOpp.Additional_Technical_Requirements1__c) restrictedFieldsChanged.add('Additional technical requirements');
               if(opp.ReasonAdditional_Technical_Requirements1__c != oldOpp.ReasonAdditional_Technical_Requirements1__c) restrictedFieldsChanged.add('Reason additional technical requirements');
               if(opp.BOM1__c != oldOpp.BOM1__c) restrictedFieldsChanged.add(' BOM1');
               if(opp.QAP__c != oldOpp.QAP__c) restrictedFieldsChanged.add('QAP');
               if(opp.Installation_Operation_Manual__c != oldOpp.Installation_Operation_Manual__c) restrictedFieldsChanged.add('Installation opertation manual');
               if(opp.Technical_Deviations__c != oldOpp.Technical_Deviations__c) restrictedFieldsChanged.add('technical deviation');
               if(opp.Transaction_Modality__c != oldOpp.Transaction_Modality__c) restrictedFieldsChanged.add('Transcation Modality');
               if(opp.Other_Transaction_Modality__c != oldOpp.Other_Transaction_Modality__c) restrictedFieldsChanged.add('Other Transcation Modality');
               if(opp.Payment_Terms1__c != oldOpp.Payment_Terms1__c) restrictedFieldsChanged.add('Payment Terms');
               if(opp.Other_Payment_Terms__c != oldOpp.Other_Payment_Terms__c) restrictedFieldsChanged.add('Other Payment Terms');
               if(opp.Payment_Term_Balance__c != oldOpp.Payment_Term_Balance__c) restrictedFieldsChanged.add('Payment Term Balance');
               if(opp.Payment_Terms__c != oldOpp.Payment_Terms__c) restrictedFieldsChanged.add('Payment Terms');
               if(opp.Other_Reason_for_Payment_Terms__c != oldOpp.Other_Reason_for_Payment_Terms__c) restrictedFieldsChanged.add('Other Reason For Payment Terms');
               if(opp.Production_Period__c != oldOpp.Production_Period__c) restrictedFieldsChanged.add('Production Period');
               if(opp.Inline_Inspection__c != oldOpp.Inline_Inspection__c) restrictedFieldsChanged.add('Inline Inspection');
               if(opp.Third_Party_Lab_Testing_if_any__c != oldOpp.Third_Party_Lab_Testing_if_any__c) restrictedFieldsChanged.add('Third Party Lab Testing If Any');
               if(opp.Incoterms__c != oldOpp.Incoterms__c) restrictedFieldsChanged.add('Incoterms');
               if(opp.Vehicle_Preference_if_any1__c != oldOpp.Vehicle_Preference_if_any1__c) restrictedFieldsChanged.add('Vehicle Prefernce If Any');
               if(opp.PalletBasedOnVehicle__c != oldOpp.PalletBasedOnVehicle__c) restrictedFieldsChanged.add('Pallet Based on Vehicle');
               if(opp.Other_Vehicle_Preference_if_any__c != oldOpp.Other_Vehicle_Preference_if_any__c) restrictedFieldsChanged.add('Other Vehicle Preference if any');
               if(opp.Vehicle_Detention_Holding_Period_Hrs__c != oldOpp.Vehicle_Detention_Holding_Period_Hrs__c) restrictedFieldsChanged.add('Vehicle Detention Holding Period Hrs');
               if(opp.Transit_Damage_Report_Claim_Period_Days__c != oldOpp.Transit_Damage_Report_Claim_Period_Days__c) restrictedFieldsChanged.add('Transit Damage Report Claim Period Days');
               if(opp.Serial_Defect_Liability__c != oldOpp.Serial_Defect_Liability__c) restrictedFieldsChanged.add('Serial Defect Liability');
               if(opp.Warranty_Terms__c != oldOpp.Warranty_Terms__c) restrictedFieldsChanged.add('Warranty Terms');
               if(opp.Other_Warranty_Terms__c != oldOpp.Other_Warranty_Terms__c) restrictedFieldsChanged.add('Other Warranty Terms');
               if(opp.Type_of_Project_Finance1__c != oldOpp.Type_of_Project_Finance1__c) restrictedFieldsChanged.add('Type of Project Finance');
               if(opp.Other_Type_of_Project_Finance__c != oldOpp.Other_Type_of_Project_Finance__c) restrictedFieldsChanged.add('Other Type of Project Finance');
               if(opp.Delivery_Schedule_Timeline__c != oldOpp.Delivery_Schedule_Timeline__c) restrictedFieldsChanged.add('Delivery Schedule Timeline');
               if(opp.Delay_LD1__c != oldOpp.Delay_LD1__c) restrictedFieldsChanged.add('Delay LD');
               if(opp.Other_Reason_for_Delay_LD__c != oldOpp.Other_Reason_for_Delay_LD__c) restrictedFieldsChanged.add('Other Reason for Delay LD');
               if(opp.Pre_Dispatch_Inspection__c != oldOpp.Pre_Dispatch_Inspection__c) restrictedFieldsChanged.add('Pre Dispatch Inspection');
               if(opp.Material_Dispatch_Clearance_Certificate__c != oldOpp.Material_Dispatch_Clearance_Certificate__c) restrictedFieldsChanged.add('Material Dispatch Clearance Certificate');
               if(opp.Delivery_Location__c != oldOpp.Delivery_Location__c) restrictedFieldsChanged.add('Delivery Location');
               if(opp.Transit_Insurance_by__c != oldOpp.Transit_Insurance_by__c) restrictedFieldsChanged.add('Transit Insurance by');
               if(opp.Vehicle_Detention_Holding_Charges_INR__c != oldOpp.Vehicle_Detention_Holding_Charges_INR__c) restrictedFieldsChanged.add('Vehicle Detention Holding Charges INR');
               if(opp.Third_Party_Warranty_Insurance__c != oldOpp.Third_Party_Warranty_Insurance__c) restrictedFieldsChanged.add('Third Party Warranty Insurance');
               if(opp.RFID_Readers_Qty__c != oldOpp.RFID_Readers_Qty__c) restrictedFieldsChanged.add('RFID Readers Qty');
               if(opp.Module_Degradation_FirstYear__c != oldOpp.Module_Degradation_FirstYear__c) restrictedFieldsChanged.add('Module Degradation FirstYear');
               if(opp.Other_Reason_for_Module_Degradation__c != oldOpp.Other_Reason_for_Module_Degradation__c) restrictedFieldsChanged.add('Other Reason for Module Degradation');
               if(opp.Delay_in_Repair_or_Replacement_Terms__c != oldOpp.Delay_in_Repair_or_Replacement_Terms__c) restrictedFieldsChanged.add('Delay in Repair or Replacement Terms');
               if(opp.Commercial_Deviations__c != oldOpp.Commercial_Deviations__c) restrictedFieldsChanged.add('Commercial Deviations');
               if(opp.Module_DegradationYoY__c != oldOpp.Module_DegradationYoY__c) restrictedFieldsChanged.add('Module Degradation YoY');
               if(opp.Other_Module_Degradation_YoY__c != oldOpp.Other_Module_Degradation_YoY__c) restrictedFieldsChanged.add('Other Module Degradation YoY');
               if(opp.Code_of_Conduct__c != oldOpp.Code_of_Conduct__c) restrictedFieldsChanged.add('Code of Conduct');
               if(opp.Change_in_Law_Taxes_Codes_Standards__c != oldOpp.Change_in_Law_Taxes_Codes_Standards__c)
                   restrictedFieldsChanged.add('Change in Law Taxes Codes Standards');
               
               if(opp.Default_Notice__c != oldOpp.Default_Notice__c)
                   restrictedFieldsChanged.add('Default Notice');
               
               if(opp.Dispute_Resolution__c != oldOpp.Dispute_Resolution__c)
                   restrictedFieldsChanged.add('Dispute Resolution');
               
               if(opp.Force_Majeure__c != oldOpp.Force_Majeure__c)
                   restrictedFieldsChanged.add('Force Majeure');
               
               if(opp.Limitation_of_Liability__c != oldOpp.Limitation_of_Liability__c)
                   restrictedFieldsChanged.add('Limitation of Liability');
               
               if(opp.Anti_Bribery_Corruption__c != oldOpp.Anti_Bribery_Corruption__c)
                   restrictedFieldsChanged.add('Anti Bribery Corruption');
               
               if(opp.Change_in_Law_Taxes_scope_during_execu__c != oldOpp.Change_in_Law_Taxes_scope_during_execu__c)
                   restrictedFieldsChanged.add('Change in Law Taxes scope during execution');
               
               if(opp.Governing_Laws_Jurisdiction_and_Arbitra__c != oldOpp.Governing_Laws_Jurisdiction_and_Arbitra__c)
                   restrictedFieldsChanged.add('Governing Laws Jurisdiction and Arbitration');
               
               if(opp.Customer_Audit_Rights__c != oldOpp.Customer_Audit_Rights__c)
                   restrictedFieldsChanged.add('Customer Audit Rights');
               
               if(opp.Termination__c != oldOpp.Termination__c)
                   restrictedFieldsChanged.add('Termination');
               
               if(opp.Legal_Deviations__c != oldOpp.Legal_Deviations__c)
                   restrictedFieldsChanged.add('Legal Deviations');
                        
               if(opp.Price_Approval_Reference__c != oldOpp.Price_Approval_Reference__c)
                    restrictedFieldsChanged.add('Price Approval Reference');
                
                if(opp.Price_Approval_Sheet__c != oldOpp.Price_Approval_Sheet__c)
                    restrictedFieldsChanged.add('Price Approval Sheet');
                
                if(opp.Proposal_Attachment__c != oldOpp.Proposal_Attachment__c)
                    restrictedFieldsChanged.add('Proposal Attachment');
                
                if(opp.Final_Wp_price_cents__c != oldOpp.Final_Wp_price_cents__c)
                    restrictedFieldsChanged.add('Final Wp price cents');
                
               // if(opp.Quote_Created_Date__c != oldOpp.Quote_Created_Date__c)
                    //restrictedFieldsChanged.add('Quote Created Date');
                
                if(opp.Discounted_Wp_Price__c != oldOpp.Discounted_Wp_Price__c)
                    restrictedFieldsChanged.add('Discounted Wp Price');
                
                if(opp.KAM_Proposed_Unit__c != oldOpp.KAM_Proposed_Unit__c)
                    restrictedFieldsChanged.add('KAM Proposed Unit');
                
                if(opp.Final_Wp_price__c != oldOpp.Final_Wp_price__c)
                    restrictedFieldsChanged.add('Final Wp price');
                
                if(opp.Purchase_Order_Contract_Reference__c != oldOpp.Purchase_Order_Contract_Reference__c)
                    restrictedFieldsChanged.add('Purchase Order Contract Reference');
                
                if(opp.Billing_Address_with_GST__c != oldOpp.Billing_Address_with_GST__c)
                    restrictedFieldsChanged.add('Billing Address with GST');
                
                if(opp.ABG_Status__c != oldOpp.ABG_Status__c)
                    restrictedFieldsChanged.add('ABG Status');
                
                if(opp.ABG_Reference__c != oldOpp.ABG_Reference__c)
                    restrictedFieldsChanged.add('ABG Reference');
                
                if(opp.ABG_Value__c != oldOpp.ABG_Value__c)
                    restrictedFieldsChanged.add('ABG Value');
                
                if(opp.ABG_Issuance_Date__c != oldOpp.ABG_Issuance_Date__c)
                    restrictedFieldsChanged.add('ABG Issuance Date');
                
                if(opp.ABG_Expiry_Date__c != oldOpp.ABG_Expiry_Date__c)
                    restrictedFieldsChanged.add('ABG Expiry Date');
                
                if(opp.ABG_Validity_Days__c != oldOpp.ABG_Validity_Days__c)
                    restrictedFieldsChanged.add('ABG Validity Days');
                
                if(opp.PDC_Reference__c != oldOpp.PDC_Reference__c)
                    restrictedFieldsChanged.add('PDC Reference');
                
                if(opp.PDC_Value__c != oldOpp.PDC_Value__c)
                    restrictedFieldsChanged.add('PDC Value');
                
                if(opp.PDC_Expiry_Date__c != oldOpp.PDC_Expiry_Date__c)
                    restrictedFieldsChanged.add('PDC Expiry Date');
                
                if(opp.Letter_of_Credit_LC__c != oldOpp.Letter_of_Credit_LC__c)
                    restrictedFieldsChanged.add('Letter of Credit LC');
                
                if(opp.LC_Usance_Interest_Cost_Buyer_Seller__c != oldOpp.LC_Usance_Interest_Cost_Buyer_Seller__c)
                    restrictedFieldsChanged.add('LC Usance Interest Cost Buyer Seller');
                
                if(opp.Finance_Review_Clearance_of_LC__c != oldOpp.Finance_Review_Clearance_of_LC__c)
                    restrictedFieldsChanged.add('Finance Review Clearance of LC');
                
                if(opp.Shipping_Address_with_GST__c != oldOpp.Shipping_Address_with_GST__c)
                    restrictedFieldsChanged.add('Shipping Address with GST');
                
                if(opp.PBG_Status__c != oldOpp.PBG_Status__c)
                    restrictedFieldsChanged.add('PBG Status');
                
                if(opp.PBG_Reference__c != oldOpp.PBG_Reference__c)
                    restrictedFieldsChanged.add('PBG Reference');
                
                if(opp.PBG_Value__c != oldOpp.PBG_Value__c)
                    restrictedFieldsChanged.add('PBG Value');
                
                if(opp.PBG_Issuance_Date__c != oldOpp.PBG_Issuance_Date__c)
                    restrictedFieldsChanged.add('PBG Issuance Date');
                
                if(opp.PBG_Expiry_Date__c != oldOpp.PBG_Expiry_Date__c)
                    restrictedFieldsChanged.add('PBG Expiry Date');
                
                if(opp.PDC_Issuance_Date__c != oldOpp.PDC_Issuance_Date__c)
                    restrictedFieldsChanged.add('PDC Issuance Date');
                
                if(opp.PBG_Validity_Days__c != oldOpp.PBG_Validity_Days__c)
                    restrictedFieldsChanged.add('PBG Validity Days');
                
                if(opp.PDC_Status__c != oldOpp.PDC_Status__c)
                    restrictedFieldsChanged.add('PDC Status');
                
                if(opp.Advance_Payment__c != oldOpp.Advance_Payment__c)
                    restrictedFieldsChanged.add('Advance Payment');
                
                if(opp.LC_Usance_Period_in_Days__c != oldOpp.LC_Usance_Period_in_Days__c)
                    restrictedFieldsChanged.add('LC Usance Period in Days');
                
                if(opp.LC_Clause_46A_Set_of_Documents__c != oldOpp.LC_Clause_46A_Set_of_Documents__c)
                    restrictedFieldsChanged.add('LC Clause 46A Set of Documents');
                        
                if(opp.Approval_status__c != oldOpp.Approval_status__c)
                    restrictedFieldsChanged.add('Approval status');
                
                if(opp.National_Head_Approval__c != oldOpp.National_Head_Approval__c)
                    restrictedFieldsChanged.add('National Head Approval');
                
                if(opp.Price_Rejection_Reason__c != oldOpp.Price_Rejection_Reason__c)
                    restrictedFieldsChanged.add('Price Rejection Reason');
                
                if(opp.MD_Approval__c != oldOpp.MD_Approval__c)
                    restrictedFieldsChanged.add('MD Approval');
                
                if(opp.MD_Rejection_Reason__c != oldOpp.MD_Rejection_Reason__c)
                    restrictedFieldsChanged.add('MD Rejection Reason');
                
                if(opp.Escalation_Comments__c != oldOpp.Escalation_Comments__c)
                    restrictedFieldsChanged.add('Escalation Comments');
                        
                if (opp.Incolocation__c != oldOpp.Incolocation__c)
                    restrictedFieldsChanged.add('Incolocation');
                
                if (opp.Ship_To_Customer_Code__c != oldOpp.Ship_To_Customer_Code__c)
                    restrictedFieldsChanged.add('Ship To Customer Code');
                
                if (opp.BillToCustomerCode__c != oldOpp.BillToCustomerCode__c)
                    restrictedFieldsChanged.add('Bill To Customer Code');
                
                if (opp.Ship_to__c != oldOpp.Ship_to__c)
                    restrictedFieldsChanged.add('Ship To');
                
                if (opp.Bill_to__c != oldOpp.Bill_to__c)
                    restrictedFieldsChanged.add('Bill To');
                
                 if (!restrictedFieldsChanged.isEmpty()) {
                   opp.addError(
                       'You cannot edit these fields during the Contract Agreement stage.\n\n' +
                       '• ' + String.join(restrictedFieldsChanged, '\n• ')
                   );
               }

            }
        
    }
}





/*public class OpportunityClosedWonValidation {
    
    public static void validate(List<Opportunity> newList, Map<Id, Opportunity> oldMap) {
        
        Set<Id> recordTypeIds = new Set<Id>();
        for (Opportunity opp : newList) {
            if (opp.RecordTypeId != null) {
                recordTypeIds.add(opp.RecordTypeId);
            }
        }
        
        Map<Id, RecordType> recordTypeMap = new Map<Id, RecordType>(
            [SELECT Id, DeveloperName FROM RecordType WHERE SObjectType = 'Opportunity' AND Id IN :recordTypeIds]);
        
        for (Opportunity opp : newList) {
            Opportunity oldOpp = (oldMap != null) ? oldMap.get(opp.Id) : null;
            RecordType rt = recordTypeMap.get(opp.RecordTypeId);
            
          
            validateMissingFields(opp, oldOpp, rt);
            
          
            validateRestrictedFieldEdits(opp, oldOpp, rt);
        }
    } 
    
    private static void validateMissingFields(Opportunity opp, Opportunity oldOpp, RecordType rt) {
        if (rt != null && rt.DeveloperName == 'Key_Account_Private' && opp.StageName != null && 
            (opp.StageName.contains('Price Approval') || opp.StageName.contains('Proposal Submission')) && 
            (oldOpp == null || oldOpp.StageName == null || !(oldOpp.StageName.contains('Price Approval') || oldOpp.StageName.contains('Proposal Submission')))) {
                
            List<String> missingFields = new List<String>();

            if (String.isBlank(opp.Transaction_Modality__c)) missingFields.add('Transaction Modality');
            if (String.isBlank(opp.Type_of_Project_Finance1__c)) missingFields.add('Type of Project Finance');
            if (opp.Payment_Terms__c == null) missingFields.add('Payment Terms');
            if (opp.Delivery_Schedule_Timeline__c == null) missingFields.add('Delivery Schedule / Timeline');
            if (opp.Production_Period__c == null) missingFields.add('Production Period');
            if (opp.Delay_LD1__c == null) missingFields.add('Delay LD');
            if (String.isBlank(opp.Pre_Dispatch_Inspection__c)) missingFields.add('Pre-Dispatch Inspection');
            if (String.isBlank(opp.Third_Party_Lab_Testing_if_any__c)) missingFields.add('Third-Party Lab Testing (if any)');
            if (opp.Material_Dispatch_Clearance_Certificate__c == null) missingFields.add('Material Dispatch Clearance Certificate');
            if (String.isBlank(opp.Delivery_Location__c)) missingFields.add('Delivery Location');
            if (String.isBlank(opp.Inline_Inspection__c)) missingFields.add('Inline Inspection');
            if (String.isBlank(opp.Incoterms__c)) missingFields.add('Incoterms');
            if (String.isBlank(opp.Vehicle_Preference_if_any1__c)) missingFields.add('Vehicle Preference (if any)');
            if (opp.Serial_Defect_Liability__c == null) missingFields.add('Serial Defect Liability');
            if (String.isBlank(opp.Transit_Insurance_by__c)) missingFields.add('Transit Insurance by');
            if (opp.Vehicle_Detention_Holding_Period_Hrs__c == null) missingFields.add('Vehicle Detention/Holding Period');
            if (String.isBlank(opp.Transit_Damage_Report_Claim_Period_Days__c)) missingFields.add('Transit Damage Report/Claim Period');
            if (opp.Third_Party_Warranty_Insurance__c == null) missingFields.add('Third-Party Warranty Insurance');
            if (opp.Warranty_Terms__c == null) missingFields.add('Warranty Terms');
            if (opp.Module_Degradation_FirstYear__c == null) missingFields.add('Module Degradation%(First Year)');
            if (opp.Module_DegradationYoY__c == null) missingFields.add('Module Degradation%(YoY)');
            if (opp.Vehicle_Detention_Holding_Charges_INR__c == null) missingFields.add('Vehicle Detention/Holding Charges (INR)');
            if (opp.Delay_in_Repair_or_Replacement_Terms__c == null) missingFields.add('Delay in Repair or Replacement - Terms');
            if (opp.Commercial_Proposal_Submission_Date__c == null) missingFields.add('Commercial Proposal Submission Date');
            if (opp.Project_capacity_in_MWp_including_Spare__c == null) missingFields.add('Project capacity in MWp including Spare');
            if (String.isBlank(opp.Wattage_Wp_Cell_Module1__c)) missingFields.add('Wattage Wp (Cell/ Module)');
            if (opp.Delivery_Schedule_Timeline__c == null) missingFields.add('Delivery Schedule / Timeline');
            if (String.isBlank(opp.Delivery_Location__c)) missingFields.add('Delivery Location');
            if (String.isBlank(opp.Ship_to__c)) missingFields.add('Ship to');
            if (String.isBlank(opp.Premier_Business_Entity1__c)) missingFields.add('Premier Business Entity');
            if (opp.RFID_Readers_Qty__c == null) missingFields.add('RFID Readers (Qty)');
            if (opp.Payment_Terms__c == null) missingFields.add('Payment Term Advance(%)');
            if (String.isBlank(opp.LC_Usance_Period_in_Days__c)) missingFields.add('LC Usance Period in Days');
            if (opp.ABG_Issuance_Date__c == null) missingFields.add('ABG Issuance Date');
            if (opp.ABG_Expiry_Date__c == null) missingFields.add('ABG Expiry Date');
            if (opp.ABG_Validity_Days__c == null) missingFields.add('ABG Validity');
            if (opp.PBG_Issuance_Date__c == null) missingFields.add('PBG Issuance Date');
            if (opp.PBG_Expiry_Date__c == null) missingFields.add('PBG Expiry Date');
            if (opp.PBG_Validity_Days__c == null) missingFields.add('PBG Validity');
            if (String.isBlank(opp.Domestic_Exports__c)) missingFields.add('Domestic/ Exports');
            if (String.isBlank(opp.Segment1__c)) missingFields.add('Segment');
            if (String.isBlank(opp.DCR_Non_DCR1__c)) missingFields.add('DCR/ Non-DCR');
            if (String.isBlank(opp.Product_Details_Technology_Type1__c)) missingFields.add('Product Details');
            if (opp.Project_capacity_in_MWp_including_Spare__c == null) missingFields.add('Project Capacity in MWp including Spare');
            if (opp.Incoterms__c == null) missingFields.add('Incoterms');
            if (String.isBlank(opp.Third_Party_Warranty_Insurance__c)) missingFields.add('Third-Party Warranty Insurance');
            if (String.isBlank(opp.Payment_Term_Balance__c)) missingFields.add('Payment Term (Balance)');
            if (opp.Vehicle_Detention_Holding_Charges_INR__c == null) missingFields.add('Vehicle Detention/Holding Charges (INR)');
            if (opp.Delay_in_Repair_or_Replacement_Terms__c == null) missingFields.add('Delay in Repair or Replacement - Terms');
            if (opp.Commercial_Deviations__c == null) missingFields.add('Commercial Deviation');

            if (!missingFields.isEmpty()) {
                opp.addError(
                    'The following fields are required:\n\n' +
                    '• ' + String.join(missingFields, '\n• ')
                );
            }
        }
    }
    
    private static void validateRestrictedFieldEdits(Opportunity opp, Opportunity oldOpp, RecordType rt) {
        if (rt != null &&
            (opp.StageName != null && (opp.StageName.contains('Price Approval') || opp.StageName.contains('Proposal Submission'))) &&
            (opp.National_Head_Approval__c == 'Approved' || opp.MD_Approval__c == 'Approved') &&
            oldOpp != null
        ) {
            List<String> restrictedFieldsChanged = new List<String>();

            if (opp.Product_Category1__c != oldOpp.Product_Category1__c)
               restrictedFieldsChanged.add('Product Category');

            if (opp.Probability != oldOpp.Probability)
               restrictedFieldsChanged.add('Probability');

            if (opp.Plant__c != oldOpp.Plant__c)
                restrictedFieldsChanged.add('Plant');
            if(opp.Name != oldOpp.Name)
            if(opp.Id__c != oldOpp.Id__c)
            if(opp.AccountId != oldOpp.AccountId)
            if(opp.Segment1__c != oldOpp.Segment__c)
            if(opp.Other_Segment__c != oldOpp.Other_Segment__c)
            if(opp.Domestic_Exports__c != oldOpp.Domestic_Exports__c)
            if(opp.Order_Type2__c != oldOpp.Order_Type2__c)
            if(opp.DCR_Non_DCR1__c != oldOpp.DCR_Non_DCR1__c)
            if(opp.Product_Type__c != oldOpp.Product_Type__c)
           
            if(opp.Other_Product__c != oldOpp.Other_Product__c)
            if(opp.Project_COD__c != oldOpp.Project_COD__c)
            if(opp.Customer_SPOC_Name__c != oldOpp.Customer_SPOC_Name__c)
            if(opp.Customer_SPOC_Mobile_No__c != oldOpp.Customer_SPOC_Mobile_No__c)
            if(opp.Financial_Due_diligence_if_any__c != oldOpp.Financial_Due_diligence_if_any__c)
            if(opp.Financial_Due_diligence_Remarks__c != oldOpp.Financial_Due_diligence_Remarks__c)
            if(opp.Tender_Requirements_if_any__c != oldOpp.Tender_Requirements_if_any__c)
            if(opp.Tender_Requirement_Remarks__c != oldOpp.Tender_Requirement_Remarks__c)
            if(opp.Contract_Closure_by__c != oldOpp.Contract_Closure_by__c)
            if(opp.Delivery_Required_by__c != oldOpp.Delivery_Required_by__c)
            if(opp.Distribution_Channel1__c != oldOpp.Distribution_Channel1__c)
            if(opp.Cable_length__c != oldOpp.Cable_length__c)
            if(opp.CloseDate != oldOpp.CloseDate)
            if(opp.Other_Details_Note__c != oldOpp.Other_Details_Note__c)
            if(opp.LC_reference__c != oldOpp.LC_reference__c)
            if(opp.Shipping_Point__c != oldOpp.Shipping_Point__c)
            if(opp.Sales_Org1__c != oldOpp.Sales_Org1__c)
            if(opp.Customer_Type__c != oldOpp.Customer_Type__c)
            if(opp.Probability != oldOpp.Probability)
            if(opp.Win_Probability_del__c != oldOpp.Win_Probability_del__c)
            if(opp.Win_Probability__c != oldOpp.Win_Probability__c)
            if(opp.StageName != oldOpp.StageName)
            if(opp.Customer_Registered_Address__c != oldOpp.Customer_Registered_Address__c)
            if(opp.Customer_Role__c != oldOpp.Customer_Role__c)
            if(opp.Other_Customer_Role__c != oldOpp.Other_Customer_Role__c)
            if(opp.End_Customer_Name_if_any__c != oldOpp.End_Customer_Name_if_any__c)
            if(opp.Project_capacity_in_MWp_including_Spare__c != oldOpp.Project_capacity_in_MWp_including_Spare__c)
            if(opp.Product_Details_Technology_Type1__c != oldOpp.Product_Details_Technology_Type1__c)
            if(opp.Other_Product_Details__c != oldOpp.Other_Product_Details__c)
            if(opp.Premier_Business_Entity1__c != oldOpp.Premier_Business_Entity1__c)
            if(opp.Wattage_Wp_Cell_Module1__c != oldOpp.Wattage_Wp_Cell_Module1__c)
            if(opp.Plant__c != oldOpp.Plant__c)
            if(opp.Customer_SPOC_EMAIL__c != oldOpp.Customer_SPOC_EMAIL__c)
            if(opp.Technical_Due_diligence_if_any__c != oldOpp.Technical_Due_diligence_if_any__c)
            if(opp.Technical_due_diligence_Remarks__c != oldOpp.Technical_due_diligence_Remarks__c)
            if(opp.Audit_Requirements_if_any__c != oldOpp.Audit_Requirements_if_any__c)
            if(opp.Audit_Rquirements_Remarks__c != oldOpp.Audit_Rquirements_Remarks__c)
            if(opp.Delivery_To_Date__c != oldOpp.Delivery_To_Date__c)
            if(opp.Order_Type__c != oldOpp.Order_Type__c)
            if(opp.Tentative_Order_Value__c != oldOpp.Tentative_Order_Value__c)
            if(opp.List_of_Pipeline_Projects__c != oldOpp.List_of_Pipeline_Projects__c)
            if(opp.Pipeline_Projects_Capacity_in_MWp__c != oldOpp.Pipeline_Projects_Capacity_in_MWp__c)
            if(opp.freight_cost__c != oldOpp.freight_cost__c)
            if(opp.Region__c != oldOpp.Region__c)
            if(opp.Legal_Review_Clearance__c != oldOpp.Legal_Review_Clearance__c)
            if(opp.Scope_Matrix_If_any__c != oldOpp.Scope_Matrix_If_any__c)
            if(opp.Product_Data_Sheet__c != oldOpp.Product_Data_Sheet__c)
            if(opp.Warranty_Manual__c != oldOpp.Warranty_Manual__c)
            if(opp.Additional_Technical_Requirements1__c != oldOpp.Additional_Technical_Requirements1__c)
            if(opp.ReasonAdditional_Technical_Requirements1__c != oldOpp.ReasonAdditional_Technical_Requirements1__c)
            if(opp.BOM1__c != oldOpp.BOM1__c)
            if(opp.QAP__c != oldOpp.QAP__c)
            if(opp.Installation_Operation_Manual__c != oldOpp.Installation_Operation_Manual__c)
            if(opp.Technical_Deviations__c != oldOpp.Technical_Deviations__c)
            if(opp.Transaction_Modality__c != oldOpp.Transaction_Modality__c)
            if(opp.Other_Transaction_Modality__c != oldOpp.Other_Transaction_Modality__c)
            if(opp.Payment_Terms1__c != oldOpp.Payment_Terms1__c)
            if(opp.Other_Payment_Terms__c != oldOpp.Other_Payment_Terms__c)
            if(opp.Payment_Term_Balance__c != oldOpp.Payment_Term_Balance__c)
            if(opp.Payment_Terms__c != oldOpp.Payment_Terms__c)
            if(opp.Other_Reason_for_Payment_Terms__c != oldOpp.Other_Reason_for_Payment_Terms__c)
            if(opp.Production_Period__c != oldOpp.Production_Period__c)
            if(opp.Inline_Inspection__c != oldOpp.Inline_Inspection__c)
            if(opp.Third_Party_Lab_Testing_if_any__c != oldOpp.Third_Party_Lab_Testing_if_any__c)
            if(opp.Incoterms__c != oldOpp.Incoterms__c)
            if(opp.Vehicle_Preference_if_any1__c != oldOpp.Vehicle_Preference_if_any1__c)
            if(opp.PalletBasedOnVehicle__c != oldOpp.PalletBasedOnVehicle__c)
            if(opp.Other_Vehicle_Preference_if_any__c != oldOpp.Other_Vehicle_Preference_if_any__c)
            if(opp.Vehicle_Detention_Holding_Period_Hrs__c != oldOpp.Vehicle_Detention_Holding_Period_Hrs__c)
            if(opp.Transit_Damage_Report_Claim_Period__c != oldOpp.Transit_Damage_Report_Claim_Period__c)
            if(opp.Serial_Defect_Liability__c != oldOpp.Serial_Defect_Liability__c)
            if(opp.Warranty_Terms__c != oldOpp.Warranty_Terms__c)
            if(opp.Other_Warranty_Terms__c != oldOpp.Other_Warranty_Terms__c)
            if(opp.Type_of_Project_Finance1__c != oldOpp.Type_of_Project_Finance1__c)
            if(opp.Other_Type_of_Project_Finance__c != oldOpp.Other_Type_of_Project_Finance__c)
            if(opp.Delivery_Schedule_Timeline__c != oldOpp.Delivery_Schedule_Timeline__c)
            if(opp.Delay_LD1__c != oldOpp.Delay_LD1__c)
            if(opp.Other_Reason_for_Delay_LD__c != oldOpp.Other_Reason_for_Delay_LD__c)
            if(opp.Pre_Dispatch_Inspection__c != oldOpp.Pre_Dispatch_Inspection__c)
            if(opp.Material_Dispatch_Clearance_Certificate__c != oldOpp.Material_Dispatch_Clearance_Certificate__c)
            if(opp.Delivery_Location__c != oldOpp.Delivery_Location__c)
            if(opp.Transit_Insurance_by__c != oldOpp.Transit_Insurance_by__c)
            if(opp.Vehicle_Detention_Holding_Charges_INR__c != oldOpp.Vehicle_Detention_Holding_Charges_INR__c)
            if(opp.Third_Party_Warranty_Insurance__c != oldOpp.Third_Party_Warranty_Insurance__c)
            if(opp.RFID_Readers_Qty__c != oldOpp.RFID_Readers_Qty__c)
            if(opp.Module_Degradation_FirstYear__c != oldOpp.Module_Degradation_FirstYear__c)
            if(opp.Other_Reason_for_Module_Degradation__c != oldOpp.Other_Reason_for_Module_Degradation__c)
            if(opp.Delay_in_Repair_or_Replacement_Terms__c != oldOpp.Delay_in_Repair_or_Replacement_Terms__c)
            if(opp.Commercial_Deviations__c != oldOpp.Commercial_Deviations__c)
            if(opp.Module_DegradationYoY__c != oldOpp.Module_DegradationYoY__c)
            if(opp.Other_Module_Degradation_YoY__c != oldOpp.Other_Module_Degradation_YoY__c)
            if(opp.Code_of_Conduct__c != oldOpp.Code_of_Conduct__c)
            if(opp.Change_in_Law_Taxes_Codes_Standards__c != oldOpp.Change_in_Law_Taxes_Codes_Standards__c)
            if(opp.Default_Notice__c != oldOpp.Default_Notice__c)
            if(opp.Dispute_Resolution__c != oldOpp.Dispute_Resolution__c)
            if(opp.Force_Majeure__c != oldOpp.Force_Majeure__c)
            if(opp.Limitation_of_Liability__c != oldOpp.Limitation_of_Liability__c)
            if(opp.Anti_Bribery_Corruption__c != oldOpp.Anti_Bribery_Corruption__c)
            if(opp.Change_in_Law_Taxes_scope_during_execu__c != oldOpp.Change_in_Law_Taxes_scope_during_execu__c)
            if(opp.Governing_Laws_Jurisdiction_and_Arbitra__c != oldOpp.Governing_Laws_Jurisdiction_and_Arbitra__c)
            if(opp.Customer_Audit_Rights__c != oldOpp.Customer_Audit_Rights__c)
            if(opp.Termination__c != oldOpp.Termination__c)
            if(opp.Legal_Deviations__c != oldOpp.Legal_Deviations__c)
            
               

            if (!restrictedFieldsChanged.isEmpty()) {
                opp.addError(
                    'You cannot modify the following fields after approval by National Head or MD:\n\n' +
                    '• ' + String.join(restrictedFieldsChanged, '\n• ')
                );
            }
        }
    }
} */









/*public class OpportunityClosedWonValidation {
    
    public static void validate(List<Opportunity> newList, Map<Id, Opportunity> oldMap) {
        
        Set<Id> recordTypeIds = new Set<Id>();
        for (Opportunity opp : newList) {
            if (opp.RecordTypeId != null) {
                recordTypeIds.add(opp.RecordTypeId);
            }
        }
        
        
        Map<Id, RecordType> recordTypeMap = new Map<Id, RecordType>(
            [SELECT Id, DeveloperName FROM RecordType WHERE SObjectType = 'Opportunity' AND Id IN :recordTypeIds]);
        
        for (Opportunity opp : newList) {
            Opportunity oldOpp = (oldMap != null) ? oldMap.get(opp.Id) : null;
            RecordType rt = recordTypeMap.get(opp.RecordTypeId);
            
            if (rt != null && rt.DeveloperName == 'Key_Account_Private' && opp.StageName != null && (opp.StageName.contains('Price Approval') || opp.StageName.contains('Proposal Submission')) && (oldOpp == null || oldOpp.StageName == null || !(oldOpp.StageName.contains('Price Approval') || oldOpp.StageName.contains('Proposal Submission')))) {
                    
                    List<String> missingFields = new List<String>();
                    
                    
         
          if (String.isBlank(opp.Transaction_Modality__c)) missingFields.add('Transaction Modality');
         if(String.isBlank(opp.Type_of_Project_Finance1__c))missingFields.add('Type of Project Finance');
          if (opp.Payment_Terms__c == null) missingFields.add('Payment Terms');
           if (opp.Delivery_Schedule_Timeline__c==null) missingFields.add('Delivery Schedule / Timeline');
                   if (opp.Production_Period__c == null) missingFields.add('Production Period');
         if (opp.Delay_LD1__c == null) missingFields.add('Delay LD');
         if (String.isBlank(opp.Pre_Dispatch_Inspection__c)) missingFields.add('Pre-Dispatch Inspection');
          if (String.isBlank(opp.Third_Party_Lab_Testing_if_any__c)) missingFields.add('Third-Party Lab Testing (if any)');
           if (opp.Material_Dispatch_Clearance_Certificate__c==null) missingFields.add('Material Dispatch Clearance Certificate');
 if (String.isBlank(opp.Delivery_Location__c)) missingFields.add('Delivery Location');
         if (String.isBlank(opp.Inline_Inspection__c)) missingFields.add('Inline Inspection');
          if (String.isBlank(opp.Incoterms__c)) missingFields.add('Incoterms');
         if (String.isBlank(opp.Vehicle_Preference_if_any1__c)) missingFields.add('Vehicle Preference (if any)');
           if (opp.Serial_Defect_Liability__c == null) missingFields.add('Serial Defect Liability');
          if (String.isBlank(opp.Transit_Insurance_by__c)) missingFields.add('Transit Insurance by');
         if (opp.Vehicle_Detention_Holding_Period_Hrs__c == null)missingFields.add('Vehicle Detention/Holding Period');
           if (String.isBlank(opp.Transit_Damage_Report_Claim_Period_Days__c)) missingFields.add('Transit Damage Report/Claim Period');
          if (opp.Third_Party_Warranty_Insurance__c == null) missingFields.add('Third-Party Warranty Insurance');
          if (opp.Warranty_Terms__c==null) missingFields.add('Warranty Terms');
                    if (opp.Module_Degradation_FirstYear__c == null) missingFields.add('Module Degradation%(First Year)');
                    if (opp.Module_DegradationYoY__c == null) missingFields.add('Module Degradation%(YoY)');
                 
                   if (opp.Vehicle_Detention_Holding_Charges_INR__c == null) missingFields.add('Vehicle Detention/Holding Charges (INR)');
                            if (opp.Delay_in_Repair_or_Replacement_Terms__c  == null) missingFields.add('Delay in Repair or Replacement - Terms');
 
                   
        
          if (opp.Commercial_Proposal_Submission_Date__c == null) missingFields.add('Commercial Proposal Submission Date');
    if (opp.Project_capacity_in_MWp_including_Spare__c==null) missingFields.add('Project capacity in MWp including Spare');
if (String.isBlank(opp.Wattage_Wp_Cell_Module1__c)) missingFields.add('Wattage Wp (Cell/ Module)');
if (opp.Delivery_Schedule_Timeline__c==null) missingFields.add('Delivery Schedule / Timeline');
if (String.isBlank(opp.Delivery_Location__c)) missingFields.add('Delivery Location');
if (String.isBlank(opp.Ship_to__c)) missingFields.add('Ship to');
if (String.isBlank(opp.Premier_Business_Entity1__c)) missingFields.add('Premier Business Entity');
if (opp.RFID_Readers_Qty__c==null) missingFields.add('RFID Readers (Qty)');
if (opp.Payment_Terms__c==null) missingFields.add('Payment Term Advance(%)');
if (String.isBlank(opp.LC_Usance_Period_in_Days__c)) missingFields.add('LC Usance Period in Days');
if (opp.ABG_Issuance_Date__c==null) missingFields.add('ABG Issuance Date');
         if(opp.ABG_Expiry_Date__c==null)missingFields.add('ABG Expiry Date');
if (opp.ABG_Validity_Days__c==null) missingFields.add('ABG Validity');
if (opp.PBG_Issuance_Date__c==null) missingFields.add('PBG Issuance Date');
         if(opp.PBG_Expiry_Date__c==null)missingFields.add('PBG Expiry Date');
if (opp.PBG_Validity_Days__c==null) missingFields.add('PBG Validity');
if (String.isBlank(opp.Domestic_Exports__c)) missingFields.add('Domestic/ Exports');
if (String.isBlank(opp.Segment1__c)) missingFields.add('Segment');
if (String.isBlank(opp.DCR_Non_DCR1__c)) missingFields.add('DCR/ Non-DCR');
if (String.isBlank(opp.Product_Details_Technology_Type1__c)) missingFields.add('Product Details');
 if (opp.Project_capacity_in_MWp_including_Spare__c == null) missingFields.add('Project Capacity in MWp including Spare');
         if (opp.Incoterms__c==null) missingFields.add('Incoterms');
if (String.isBlank(opp.Third_Party_Warranty_Insurance__c)) missingFields.add('Third-Party Warranty Insurance');

if (String.isBlank(opp.Payment_Term_Balance__c)) missingFields.add('Payment Term (Balance)');
if (opp.Vehicle_Detention_Holding_Charges_INR__c == null) 
    missingFields.add('Vehicle Detention/Holding Charges (INR)');

if (opp.Delay_in_Repair_or_Replacement_Terms__c == null) 
    missingFields.add('Delay in Repair or Replacement - Terms');

if(opp.Commercial_Deviations__c==null)
    missingFields.add('Commercial Deviation');



                    
         
         if (!missingFields.isEmpty()) {
                        opp.addError(
                            'The following fields are required:\n\n' +
                            '• ' + String.join(missingFields, '\n• ')
                        );
                    }
     }            }
    } 

} */