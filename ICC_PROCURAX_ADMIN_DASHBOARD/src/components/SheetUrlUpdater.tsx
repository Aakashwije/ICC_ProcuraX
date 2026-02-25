import React, { useState } from "react";
import { updateUserSheetUrl } from "../services/api";

interface SheetUrlUpdaterProps {
  userId: string;
  token?: string;
}

const SheetUrlUpdater: React.FC<SheetUrlUpdaterProps> = ({ userId, token }) => {
  const [sheetUrl, setSheetUrl] = useState("");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");
  const [success, setSuccess] = useState("");

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError("");
    setSuccess("");
    try {
      await updateUserSheetUrl(userId, sheetUrl, token);
      setSuccess("Sheet URL updated successfully!");
    } catch (err: any) {
      setError(err.message || "Failed to update sheet URL.");
    } finally {
      setLoading(false);
    }
  };

  return (
    <form onSubmit={handleSubmit} style={{ maxWidth: 400 }}>
      <label htmlFor="sheetUrl">Google Sheet Link/ID:</label>
      <input
        id="sheetUrl"
        type="text"
        value={sheetUrl}
        onChange={e => setSheetUrl(e.target.value)}
        placeholder="Paste Google Sheet link or ID"
        style={{ width: "100%", marginBottom: 8 }}
        required
      />
      <button type="submit" disabled={loading} style={{ width: "100%" }}>
        {loading ? "Updating..." : "Update Sheet Link"}
      </button>
      {error && <div style={{ color: "red", marginTop: 8 }}>{error}</div>}
      {success && <div style={{ color: "green", marginTop: 8 }}>{success}</div>}
    </form>
  );
};

export default SheetUrlUpdater;
