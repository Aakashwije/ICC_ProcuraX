// PATCH user's googleSheetUrl
export async function updateUserSheetUrl(userId: string, sheetUrl: string, token?: string) {
  const response = await fetch(`${process.env.NEXT_PUBLIC_BACKEND_URL || "http://localhost:3000"}/admin-users/${userId}/sheet-url`, {
    method: "PATCH",
    headers: {
      "Content-Type": "application/json",
      ...(token ? { Authorization: `Bearer ${token}` } : {})
    },
    body: JSON.stringify({ googleSheetUrl: sheetUrl })
  });
  if (!response.ok) {
    throw new Error(`Failed to update sheet URL: ${response.status}`);
  }
  return await response.json();
}
