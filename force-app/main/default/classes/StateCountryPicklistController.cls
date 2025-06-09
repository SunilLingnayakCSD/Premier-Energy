public with sharing class StateCountryPicklistController {

    public class CountryStateWrapper {
        @AuraEnabled public String countryCode;
        @AuraEnabled public List<String> states;

        public CountryStateWrapper(String countryCode, List<String> states) {
            this.countryCode = countryCode;
            this.states = states;
        }
    }

    public class CountryStateData {
        @AuraEnabled public List<String> countries;
        @AuraEnabled public List<CountryStateWrapper> states;
    }

    @AuraEnabled(cacheable=true)
    public static CountryStateData getCountryStatePicklists() {
        CountryStateData data = new CountryStateData();

        // Get country picklist values from Account.BillingCountryCode
        List<String> countryList = new List<String>();
        Schema.DescribeFieldResult countryField = Account.BillingCountryCode.getDescribe();
        for (Schema.PicklistEntry entry : countryField.getPicklistValues()) {
            countryList.add(entry.getlabel());
        }
        data.countries = countryList;

        // Get states per country using Account.BillingStateCode
        List<CountryStateWrapper> stateWrappers = new List<CountryStateWrapper>();
        Schema.DescribeFieldResult stateField = Account.BillingStateCode.getDescribe();

        for (String countryCode : countryList) {
            List<String> stateList = new List<String>();
            // NOTE: PicklistValuesForCountry is on DescribeFieldResult for compound address fields via getPicklistValues(), not directly by country in Apex yet.
            // So we fetch all values and filter manually if needed (assuming values include country context in label or value)
            for (Schema.PicklistEntry entry : stateField.getPicklistValues()) {
                // If your org has State/Country picklists enabled, you'd filter states by country mapping metadata
                stateList.add(entry.getlabel());
            }

            stateWrappers.add(new CountryStateWrapper(countryCode, stateList));
        }

        data.states = stateWrappers;

        return data;
    }
	


    

    
       

    
   





}