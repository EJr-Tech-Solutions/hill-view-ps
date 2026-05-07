// Paste this in browser console (F12) to fix auth and reload data
(async function() {
  console.log('Fixing auth and reloading...');

  // Clear all storage
  localStorage.clear();
  sessionStorage.clear();

  // Clear IndexedDB (where Supabase stores sessions)
  const dbs = await indexedDB.databases();
  for (const db of dbs) {
    await new Promise((resolve) => {
      const req = indexedDB.deleteDatabase(db.name);
      req.onsuccess = resolve;
      req.onerror = resolve;
    });
  }

  console.log('Storage cleared. Reloading...');
  location.reload();
})();
