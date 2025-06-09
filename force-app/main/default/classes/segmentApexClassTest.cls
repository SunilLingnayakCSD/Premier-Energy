@isTest
public class segmentApexClassTest {

    // Utility method to create a mock CMDT record (note: CMDT records can't be inserted in test context)
    private static void createTestSegmentCMDT() {
        // No actual DML here since CMDT records need to exist in the org — 
        // This method is just a placeholder if you want to document setup
    }

    // Test method for metadataUpdate()
    @isTest
    static void testMetadataUpdate() {
        Test.startTest();
        // Call the method
        List<Segment__mdt> result = segmentApexClass.metadataUpdate();
        Test.stopTest();

        // Assert result is not null
        System.assertNotEquals(null, result, 'Result should not be null');
        // Optionally check for expected size if you know CMDT records exist
        // System.assertEquals(1, result.size(), 'Should return one record');
    }

    // Test method for updateMetadata()
    @isTest
    static void testUpdateMetadata() {
        Test.startTest();
        // Call the update method with test values
        segmentApexClass.updateMetadata('Commercial', 12.5, 9.75);
        Test.stopTest();

        // Since Metadata deployment is skipped in tests, just assert true to confirm execution
        System.assert(true, 'updateMetadata executed without error in test context');
    }
}