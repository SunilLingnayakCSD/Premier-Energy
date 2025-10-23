trigger TurnOverDiscountsTrigger on TurnOver_Discounts__c (before insert, before update) {
    if (Trigger.isBefore) {
        if (Trigger.isInsert) {
            TODAchievementHandler.calculateTODAchievements(Trigger.new, null);
        } else if (Trigger.isUpdate) {
            TODAchievementHandler.calculateTODAchievements(Trigger.new, Trigger.oldMap);
        }
    }
}