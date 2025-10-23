global without sharing class HandleCustomException extends Exception {
    
    // Overload 1 – Log exception without related record
    public static void LogException(Exception e) {
        LogException(e, null);
    }

    // Overload 2 – Log exception with related record ID
    public static void LogException(Exception e, String relatedToId) {
        try {
            String stackTrace = e.getStackTraceString().substringBefore('\n');
            String className = stackTrace.substringAfter('.').substringBefore('.');
            String methodName = stackTrace.substringBefore(':').substringAfter(className).substringAfter('.');

            // Governor limits snapshot
            String queryLimit = '1. SOQL Queries used / allowed: ' + Limits.getQueries() + '/' + Limits.getLimitQueries();
            String dmlLimit = '2. DML Rows used / allowed: ' + Limits.getDmlRows() + '/' + Limits.getLimitDmlRows();
            String dmlStat  = '3. DML Statements used / allowed: ' + Limits.getDmlStatements() + '/' + Limits.getLimitDmlStatements();
            String cpuTime  = '4. CPU time used / allowed (ms): ' + Limits.getCpuTime() + '/' + Limits.getLimitCpuTime();

            // Log into custom object
            CustomException__c exc = new CustomException__c();
            exc.Related_To_Number__c = relatedToId;
            exc.Exception_Message__c = e.getMessage();
            exc.Exception_Type__c = e.getTypeName();
            exc.Line_Number__c = e.getLineNumber();
            exc.StackTrace__c = e.getStackTraceString();
            exc.ClassName__c = className;
            exc.MethodName__c = methodName;
            exc.Govt_Limit_in_Executing_Code__c = String.join(new List<String>{ queryLimit, dmlLimit, dmlStat, cpuTime }, '\n');

            insert exc;

        } catch (Exception loggingError) {
            // Optional fallback: log error to debug if CustomException insert fails
            System.debug('Failed to log exception: ' + loggingError.getMessage());
        }
    }
}