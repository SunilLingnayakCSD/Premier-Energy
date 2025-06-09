/**
* @File Name : ProductRawMaterialController.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : February 25, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | February 25, 2025 |   | Initial Version
**/

public class ProductRawMaterialController {

    @AuraEnabled(cacheable=true)
    public static List<Raw_Materials__c> getAllRawMaterials() {
        // Query all available raw materials (adjust as needed to filter based on your logic)
       List<Raw_Materials__c> rawMaterialsList = [SELECT Id, Name,UOM__c,Quantity__c,Material_Cost__c FROM Raw_Materials__c];
      system.debug('rawMaterialsList: ' + rawMaterialsList);
       return rawMaterialsList;
    }

    @AuraEnabled(cacheable=true)
    public static List<Product_Raw_Materials__c> getRawMaterialsForOpportunity(Id opportunityId) {
        // Query OpportunityLineItems to get related Product2Id
        List<OpportunityLineItem> oppLineItems = [SELECT Id, Product2Id FROM OpportunityLineItem WHERE OpportunityId = :opportunityId];
        
        system.debug('oppLineItems: ' + oppLineItems);  // Debugging the OpportunityLineItems

        // Create a list to store raw materials associated with the products
        Set<Id> productIds = new Set<Id>();
        for (OpportunityLineItem oli : oppLineItems) {
            productIds.add(oli.Product2Id);
        }

        system.debug('productIds: ' + productIds);  // Debugging the Product2Ids

        // Now query the Product_Raw_Materials__c for the related raw materials for the products
        List<Product_Raw_Materials__c> rawMaterials = [SELECT Id, Raw_Materials__r.Name, Raw_Materials__r.UOM__c,Raw_Materials__r.Quantity__c,Raw_Materials__r.Material_Cost__c FROM Product_Raw_Materials__c WHERE Product__c IN :productIds];

        // Debugging the raw materials result before returning
        system.debug('rawMaterials: ' + rawMaterials);

        return rawMaterials;  // Returning the raw materials
    }

  @AuraEnabled(cacheable=true)
public static List<Raw_Materials__c> getSubstituteRawMaterials() {
    try {
        List<Raw_Materials__c> substituteMaterials = [SELECT Id, Name FROM Raw_Materials__c ];//Is_Substitute__c = TRUE
        System.debug('Substitute Materials: ' + substituteMaterials);
        return substituteMaterials;
    } catch (Exception e) {
        System.debug('Error fetching substitute raw materials: ' + e.getMessage());
        return new List<Raw_Materials__c>();
    }
}


    // Update the raw material with the selected substitute
    @AuraEnabled
    public static void updateRawMaterial(Id rawMaterialId, Id substituteRawMaterialId) {
        try {
            // Query to get the current raw material that needs to be updated
            Product_Raw_Materials__c productRawMaterial = [
                SELECT Id, Raw_Materials__c
                FROM Product_Raw_Materials__c
                WHERE Raw_Materials__c = :rawMaterialId
                LIMIT 1
            ];

            // If a record is found, update it with the substitute
            if (productRawMaterial != null) {
                productRawMaterial.Raw_Materials__c = substituteRawMaterialId;
                update productRawMaterial;  // Perform the update
            } else {
                throw new AuraHandledException('Raw Material not found for update');
            }
        } catch (Exception e) {
            // Handle any errors during the update process
            throw new AuraHandledException('Error updating raw material: ' + e.getMessage());
        }
    }

   
    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getRawMaterials() {
        List<Map<String, String>> rawMaterialOptions = new List<Map<String, String>>();
        
        // Query the Raw Material records (you can adjust this query according to your actual object and field names)
        List<Raw_Materials__c> rawMaterials = [SELECT Id, Name FROM Raw_Materials__c];
        
        // Add options for the combobox
        for (Raw_Materials__c material : rawMaterials) {
            Map<String, String> option = new Map<String, String>();
            option.put('label', material.Name);  // Display name
            option.put('value', material.Id);    // Actual value to send
            rawMaterialOptions.add(option);
        }
        
        return rawMaterialOptions;
    }


}