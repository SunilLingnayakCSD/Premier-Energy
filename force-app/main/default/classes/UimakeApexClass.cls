public class UimakeApexClass {
    @AuraEnabled(cacheable=true)
    public static List<Raw_Materials__c> RawMaterialsNamesQueryANdUom(String searchKey){
        // search the user input
        String searchvalue ='%' + searchKey + '%';
        // Query to fetch all raw materials
        List<Raw_Materials__c> queryRaw = [SELECT Name,
                                           		  Sort__c,
                                                  UOM__c, 
                                                  China_Make1__c, 
                                                  China_Make2__c, 
                                                  China_Make3__c, 
                                                  China_Make4__c, 
                                                  China_Low_Price__c,
                                                  China_Average_Price__c,

                                                  India_Make1__c,
                                                  India_Make2__c,
                                                  India_Make3__c,
                                                  India_Make4__c,
                                                  India_Low_Price__c,
                                                  India_Average_Price__c,

                                                  Malaysia_Make1__c,
                                                  Malaysia_Make2__c,
                                                  Malaysia_Make3__c,
                                                  Malaysia_Make4__c,
                                                  Malaysia_Low_Price__c,
                                                  Malaysia_Average_Price__c,

                                                  Vietnam_Make1__c,
                                                  Vietnam_Make2__c,
                                                  Vietnam_Make3__c,
                                                  Vietnam_Make4__c,
                                                  Vietnam_Low_Price__c,
                                                  Vietnam_Average_Price__c
                                            FROM Raw_Materials__c WHERE Name LIKE :searchvalue ORDER By Sort__c ASC];
        return queryRaw;
    }
}