ISubscription subscription = null;

//These two objects contain the properties and methods for 
//retrieving the synchronization status information.
subscription = server.GetSubscription();

//If the synchronization process is currently running, print its progress.
while (SynchronizationStatus.Running == subscription.GetSynchronizationStatus())
{
//  SynchronizationProgress progress = subscription.GetSynchronizationProgress();

//  Console.WriteLine("{0}% of {1} synchronized.", 
//      100*progress.ProcessedItems/progress.TotalItems,
//      (SynchronizationPhase.Updates) ? "updates" : "approvals");

  System.Threading.Thread.Sleep(500);
};

//If the synchronization process is not running, check if it has succeeded.
if (SynchronizationStatus.NotProcessing == subscription.GetSynchronizationStatus())
{
  ISynchronizationInfo lastSyncInfo = subscription.GetLastSynchronizationInfo();

  //Check the result to see if the synchronization process has succeeded.
  switch (lastSyncInfo.Result)
  {
    case SynchronizationResult.Succeeded :
      Console.WriteLine("Synchronization completed on {0}.", 
                        lastSyncInfo.EndTime.ToLocalTime().ToString());
      break;

    case SynchronizationResult.Failed :
      Console.WriteLine("Synchronization failed with error, {0}, on {1}.", 
                        lastSyncInfo.Error, lastSyncInfo.EndTime.ToLocalTime().ToString());
      Console.WriteLine(lastSyncInfo.ErrorText);

      //The synchronization process could also fail with an import error, 
      //so also check UpdateErrors.
      foreach (SynchronizationUpdateErrorInfo importError in lastSyncInfo.UpdateErrors)
      {
        Console.WriteLine("Failed to import update, {0}\nReason: {1}\n",
                          server.GetUpdate(importError.UpdateId).Title,
                          importError.ErrorText);
      }

      break;

    case SynchronizationResult.Canceled :
    {
      Console.WriteLine("The synchronization process was canceled.");
      break;
    }

    case SynchronizationResult.NeverRun : 
      Console.WriteLine("Synchronization has never been run on this WSUS server.");
      break;

    case SynchronizationResult.Unknown :
      Console.WriteLine("Synchronization ended for an unknown reason.");
      break;

    default :
      Console.WriteLine("Unknown synchronization result code, {0}.", lastSyncInfo.Result);
      break;
  }

  if (true == subscription.SynchronizeAutomatically)
  {
    Console.WriteLine("The next synchronization process is scheduled to occur at {0}", 
                      subscription.GetNextSynchronizationTime().ToLocalTime().ToString());
  }
}
else
{
  Console.WriteLine("The synchronization process is stopping. Try again later.");
}
