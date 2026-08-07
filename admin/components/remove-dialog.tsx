"use client";

import { useState } from "react";
import { XCircle, X } from "lucide-react";
import { directRemovePost } from "@/app/moderation/actions";

const VIOLATION_REASONS = [
  "threats",
  "pii",
  "sexual",
  "hate",
  "spam",
  "other",
];

interface RemoveDialogProps {
  postId: string;
  postText: string;
  onClose: () => void;
}

export default function RemoveDialog({
  postId,
  postText,
  onClose,
}: RemoveDialogProps) {
  const [selectedReason, setSelectedReason] = useState<string>("");
  const [adminNote, setAdminNote] = useState<string>("");
  const [loading, setLoading] = useState(false);

  async function handleConfirm() {
    if (!selectedReason) return;
    setLoading(true);
    const result = await directRemovePost(
      postId,
      selectedReason,
      adminNote || undefined
    );
    if (result.error) {
      alert(`Error: ${result.error}`);
    }
    setLoading(false);
    onClose();
  }

  return (
    <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
      <div className="bg-white rounded-lg shadow-lg max-w-md w-full mx-4">
        <div className="flex items-center justify-between px-4 py-3 border-b border-gray-200">
          <h3 className="font-semibold text-sm flex items-center gap-2">
            <XCircle size={16} className="text-red-600" />
            Remove Post
          </h3>
          <button
            onClick={onClose}
            className="text-gray-400 hover:text-gray-600"
          >
            <X size={18} />
          </button>
        </div>

        <div className="p-4">
          <div className="bg-gray-50 rounded border border-gray-200 px-3 py-2 mb-4">
            <p className="text-sm text-gray-700 line-clamp-3">{postText}</p>
          </div>

          <p className="text-xs font-medium text-gray-700 mb-2">
            Violation reason:
          </p>
          <div className="flex flex-wrap gap-2 mb-3">
            {VIOLATION_REASONS.map((reason) => (
              <button
                key={reason}
                onClick={() => setSelectedReason(reason)}
                className={`px-3 py-1 text-xs rounded-full border transition-colors ${
                  selectedReason === reason
                    ? "bg-red-600 text-white border-red-600"
                    : "bg-white text-gray-700 border-gray-300 hover:border-red-300"
                }`}
              >
                {reason}
              </button>
            ))}
          </div>

          <input
            type="text"
            value={adminNote}
            onChange={(e) => setAdminNote(e.target.value)}
            placeholder="Optional admin note..."
            className="w-full text-sm border border-gray-300 rounded-md px-3 py-1.5 mb-4"
          />

          <div className="flex gap-2 justify-end">
            <button
              onClick={onClose}
              className="px-3 py-1.5 text-xs font-medium rounded-md bg-gray-100 text-gray-700 hover:bg-gray-200 transition-colors"
            >
              Cancel
            </button>
            <button
              onClick={handleConfirm}
              disabled={loading || !selectedReason}
              className="px-3 py-1.5 text-xs font-medium rounded-md bg-red-600 text-white hover:bg-red-700 disabled:opacity-50 transition-colors"
            >
              {loading ? "Removing..." : "Confirm Remove"}
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}
