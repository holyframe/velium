import SupportVelium from '../../components/settings/supportVelium/SupportVeliumDashboard';
import ErrorBoundary from '../../components/util/ErrorBoundary';

const SupportScreen = () => {
  return (
    <ErrorBoundary>
      <SupportVelium />
    </ErrorBoundary>
  );
};

export default SupportScreen;
