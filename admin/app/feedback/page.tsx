import { supabaseAdmin } from "@/lib/supabase-admin";
import type { Feedback } from "@/lib/types";

export const dynamic = "force-dynamic";

async function getFeedback(): Promise<Feedback[]> {
  const { data, error } = await supabaseAdmin
    .from("feedback")
    .select(
      "*, user:users(username, user_number)"
    )
    .order("created_at", { ascending: false });

  if (error) {
    console.error("feedback fetch error:", error);
    return [];
  }
  if (!data) return [];

  return data as Feedback[];
}

export default async function FeedbackPage() {
  const feedback = await getFeedback();

  return (
    <div>
      <div className="flex items-center justify-between mb-6">
        <h2 className="text-2xl font-bold">Feedback</h2>
        <span className="text-sm text-gray-500">
          {feedback.length} submission{feedback.length !== 1 ? "s" : ""}
        </span>
      </div>

      {feedback.length === 0 ? (
        <div className="bg-white rounded-lg border border-gray-200 p-8 text-center text-gray-500">
          No feedback submitted yet.
        </div>
      ) : (
        <div className="bg-white rounded-lg border border-gray-200 overflow-hidden">
          <table className="w-full text-sm">
            <thead className="bg-gray-50 border-b border-gray-200">
              <tr>
                <th className="text-left px-4 py-3 font-medium text-gray-500">
                  User
                </th>
                <th className="text-left px-4 py-3 font-medium text-gray-500">
                  Feedback
                </th>
                <th className="text-left px-4 py-3 font-medium text-gray-500">
                  Submitted
                </th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-100">
              {feedback.map((item) => (
                <tr key={item.id} className="hover:bg-gray-50">
                  <td className="px-4 py-3 font-medium whitespace-nowrap">
                    {item.user
                      ? `${item.user.username}#${item.user.user_number}`
                      : "—"}
                  </td>
                  <td className="px-4 py-3 text-gray-600">{item.body}</td>
                  <td className="px-4 py-3 text-gray-500 whitespace-nowrap">
                    {new Date(item.created_at).toLocaleDateString()}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}
