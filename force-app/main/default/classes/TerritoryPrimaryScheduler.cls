/**
 * @description  Schedulable wrapper for TerritoryPrimaryBatch.
 *               Runs nightly at 2:00 AM to catch territory assignment changes
 *               that are not handled in real-time (Salesforce ETM does not
 *               support Apex triggers on ObjectTerritory2Association).
 *
 *               Register via Execute Anonymous:
 *                   System.schedule(
 *                       'Territory Primary Nightly',
 *                       '0 0 2 * * ?',
 *                       new TerritoryPrimaryScheduler()
 *                   );
 *
 * @author       Seth Sheppard
 * @since        2026-02-18
 */
public class TerritoryPrimaryScheduler implements Schedulable {

    public void execute(SchedulableContext sc) {
        Database.executeBatch(new TerritoryPrimaryBatch(), 2000);
    }
}