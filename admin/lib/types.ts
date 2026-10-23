export type PostStatus = "live" | "under_review" | "removed";

export interface Neighborhood {
  id: string;
  name: string;
  short_code: string;
  borough: string;
}

export interface User {
  id: string;
  username: string;
  user_number: number;
  home_neighborhood_id: string | null;
  home_changed_at: string | null;
  is_seed: boolean;
  created_at: string;
  neighborhood?: Neighborhood;
}

export interface Post {
  id: string;
  user_id: string;
  neighborhood_id: string;
  text: string;
  image_url: string | null;
  pin_id: string | null;
  is_daily_prompt: boolean;
  daily_prompt_id: string | null;
  score: number;
  reply_count: number;
  report_count: number;
  status: PostStatus;
  created_at: string;
  author?: { username: string; user_number: number };
  neighborhood?: { name: string };
}

export interface Report {
  id: string;
  reporter_id: string;
  post_id: string;
  reason: string;
  free_text: string | null;
  created_at: string;
  reporter?: { username: string };
}

export interface ModerationPost extends Post {
  reports: Report[];
}

export interface Feedback {
  id: string;
  user_id: string;
  body: string;
  created_at: string;
  user?: { username: string; user_number: number };
}

export interface ModerationAction {
  id: string;
  post_id: string;
  user_id: string | null;
  action: "remove" | "restore" | "uphold" | "overturn";
  reason: string | null;
  admin_note: string | null;
  created_at: string;
}

export interface Strike {
  id: string;
  user_id: string;
  post_id: string;
  moderation_action_id: string;
  created_at: string;
}

export type AppealStatus = "pending" | "accepted" | "rejected";

export interface Appeal {
  id: string;
  user_id: string;
  post_id: string;
  appeal_text: string;
  status: AppealStatus;
  created_at: string;
  user?: { username: string; user_number: number };
  post?: Post;
}

/** One "Prove you're a real New Yorker" survey submission (Supabase/00034). */
export interface SurveyResponse {
  id: string;
  created_at: string;
  src: "p1" | "p2" | "p3" | "direct";
  q1_choice: string | null;
  q1_text: string | null;
  q2_choice: string | null;
  q2_text: string | null;
  q3_choice: string | null;
  q4_choice: string | null;
  q5_choice: string | null;
  q6_choice: string | null;
  q7_text: string | null;
  score: number;
  tier: "CITY SLICKER" | "BLOCKTALKER" | "TRANSPLANT" | "TOURIST";
  email: string;
  neighborhood: string;
  phone: string | null;
  sms_consent: boolean;
  contacted: boolean;
  user_agent: string | null;
}
