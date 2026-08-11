import React from "react";
import { motion } from "framer-motion";

interface RevealProps {
  children: React.ReactNode;
  /** Stagger helper — seconds to delay the entrance. */
  delay?: number;
  /** Initial vertical offset in px. */
  y?: number;
}

/**
 * Subtle fade-up on scroll-into-view. Used to give customer-facing sections a
 * consistent, market-standard entrance animation (Sand & Indigo refresh).
 */
const Reveal: React.FC<RevealProps> = ({ children, delay = 0, y = 28 }) => (
  <motion.div
    initial={{ opacity: 0, y }}
    whileInView={{ opacity: 1, y: 0 }}
    viewport={{ once: true, amount: 0.15 }}
    transition={{ duration: 0.55, ease: [0.22, 1, 0.36, 1], delay }}
  >
    {children}
  </motion.div>
);

export default Reveal;
